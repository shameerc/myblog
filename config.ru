
require './toto/lib/toto.rb'

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico','/robots.txt'], :root => 'public'
use Rack::CommonLogger

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
end

#
# Create and configure a toto instance
#
toto = Toto::Server.new do
  #
  # Add your settings here
  # set [:setting], [value]
  # 
   set :author,    'Shameer C'                                # blog author
   set :title,     'Tech Blog of Shameer C'                   # site title
  # set :root,      "index"                                   # page to load on /
  # set :date,      lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
  # set :markdown,  :smart                                    # use markdown + smart-mode
   set :disqus,    'shameerblog'                                     # disqus id, or false
  # set :summary,   :max => 150, :delim => /~/                # length of article summary and delimiter
  # set :ext,       'txt'                                     # file extension for articles
  # set :cache,      28800                                    # cache duration, in seconds
  set :suffix, '.html'
  set :dateformat, '%Y/%m'
  set :url, 'http://0.0.0.0:3000'
  set :date, lambda {|now| now.strftime("%B #{now.day.ordinal} %Y") }
end
run toto


