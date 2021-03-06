require 'rubygems'
require 'bundler/setup'
require 'logger'
require 'sinatra'
require 'mongoid'
require 'haml'
require 'sass'
require 'unicode'
require './models'
require 'rack/cache'
require 'yajl/json_gem'

set :root, File.dirname(__FILE__) # <- do we need this? // check to see if templating breaks without it
set :haml, :format => :html5

BASE_URL = "http://skoleporten.bengler.no"

configure :development do
    Mongoid.configure do |config|
      name = "skoolgate_development"
      host = "localhost"
      config.master = Mongo::Connection.new.db(name, :logger => './log/mongo.log')
      config.slaves = [
      Mongo::Connection.new(host, 27017, :slave_ok => true).db(name)
    ]
    config.persist_in_safe_mode = false

    # use Rack::Cache,
    #   :verbose     => true,
    #   :metastore   => 'memcached://localhost:11211/meta',
    #   :entitystore => 'memcached://localhost:11211/body'

  end
end

configure :production do
  Mongoid.configure do |config|
    name = "skoolgate_production"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name, :logger => Logger.new(STDOUT))
    config.slaves = [
      Mongo::Connection.new(host, 27017, :slave_ok => true).db(name)
    ]
    config.persist_in_safe_mode = false
  end
  
  before do
    cache_control :public, :max_age => 172800
  end

  use Rack::Cache,
    :verbose     => true,
    :metastore   => 'memcached://localhost:11211/meta',
    :entitystore => 'memcached://localhost:11211/body'
end
