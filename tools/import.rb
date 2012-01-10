#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'time'
require '../config.ru'

config = {
  :date_format => '%Y-%m'  
}

puts ARGV[0]
file = File.new(ARGV[0])
oFile = File.open(ARGV[0])
doc = Hpricot( oFile )
nginx_rewrite = File.open('./rewrite.nginx', 'w')
rack_rewrite = File.open('./rewrite.rack', 'w')

puts "Importing WordPress posts...\n\n"

(doc/"item").each do |item|
if item.search("wp:post_type").first.inner_text == "post" and item.search("wp:status").first.inner_text == "publish" then
  is_private = ( item.search("wp:status").first.inner_text == "private" )
  
  next if item.search("wp:post_type").first.inner_text != "post"
  
  post_id = item.search("wp:post_id").first.inner_text.to_i
  title = item.search("title").first.inner_text.gsub(/:/, '')
  
  slug = title.empty?? nil : title.strip.slugize
  time = Time.parse item.search("wp:post_date").first.inner_text
  link = item.search("link").first.inner_text

  tags = item.search("category[@domain='post_tag']").collect{|n| n[:nicename]}.uniq
  tags = tags.map { |t| t.downcase }.sort.uniq

  category = item.search("category[@domain='category']").collect{|n| n[:nicename]}.uniq
  category = category.map { |t| t.downcase }.sort.uniq.join('/')
  category = '' if category == "uncategorized"
  
  content = item.search("content:encoded").first.inner_text.to_s
 
  if content.strip.empty?
    puts "Failed to parse postId #{post_id}:#{title}"
    next
  end
  
  # If you use a differing format for the slug, you should change this strftime
  path = "./articles/#{time.strftime("#{config[:date_format]}")}#{'-' + slug if slug}.txt"

  new_url = "/#{time.strftime("%Y/%m/%d")}#{'/' + slug if slug}"
  nginx_rewrite.puts "rewrite ^/(?p=|archives/)#{post_id}$ #{new_url} permanent;\n"
  rack_rewrite.puts "r301 %r{/^(?:\\?p=|archives/)#{post_id}$}, '#{new_url}'\n"
  
  begin 
    newpost = File.open(path,'w')
    newpost.puts "---\n"
    newpost.puts "title: #{title.chomp}\n"

    # You can replace this later with sed:
    # $ sed -i 's/%AUTHOR%/My Real Name/' /path/to/articles/*
    newpost.puts "author: %AUTHOR%\n"

    # If you use a differing format for the date, you might need to change this strftime
    newpost.puts "date: #{time.strftime("%d/%m/%Y")}\n"

    newpost.puts "category: #{category}\n" unless category.empty?
    newpost.puts "tags: #{tags.join(', ')}\n"
    newpost.puts "\n"

    # Later you may replace excerpt separator easily with sed:
    # $ sed -i 's/<!-- more -->/~~~/' /path/to/articles/*
    newpost.puts content

    puts "##{post_id}: #{title.chomp} --> #{path}\n"
  rescue Exception => e  
    puts e.message  
    puts e.backtrace.inspect  
    puts "ERROR! could not save post #{title}"
    exit
  end  
end
end

puts "\n\nHooray! Import complete!\n\n"
puts "- to fix %AUTHOR% metadata stubs in all imported articles, run:\n"
puts "  $ sed -i 's/%AUTHOR%/My Real Name/' ./articles/*\n\n"
puts "- to fix excerpt delimiter in all imported articles, run:\n"
puts "  $ sed -i 's/<!-- more -->/~\\n/' ./articles/*\n\n"
puts "- to set old to new URLs permanent redirects with nginx:\n"
puts "  See nginx manual on http://wiki.nginx.org/HttpRewriteModule\n"
puts "  You will find full map of redirect rules in `rewrite.nginx`\n\n"
puts "- to set old to new URLs permanent redirects with Rack::Rewrite:\n"
puts "  Put following into your config.ru file:\n\n"
puts "  require 'rack/rewrite'\n"
puts "  use Rack::Rewrite do\n"
puts "    # content of rewrite.rack here\n"
puts "  end\n\n"
puts "Have fun in a Wonderland of Oz!\n"
