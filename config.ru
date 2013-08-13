$:.unshift(File.join(File.dirname(__FILE__), "app"))
ENV['BUNDLE_GEMFILE'] = File.join( File.expand_path(File.dirname(__FILE__)), "Gemfile" )
require 'rubygems'
require 'bundler'
Bundler.setup
require 'rack'
require 'json'
require 'rack/contrib'
require 'rack/contrib/not_found'
require 'rack/contrib/jsonp'
require 'rack/session/cookie'

if ENV['RACK_ENV'] == 'test'
  # start Riak test server
  $:.unshift(File.join(File.dirname(__FILE__)))
  require 'test/support/ripple_test_server.rb'
end

require 'app'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :expire_after => 2592000,
                           :secret => '0556222a6dfeaf094ed26d871ccd30a380dcf0ed9a47b517fb4a0ce4f5cac836d240f9563438a11b3fa6e35ca03631e4a0e5b95d15d8d982f09fdb685696679f'

# Use jsonp
#use Rack::JSONP

# Enron
use API::V1::Email
use API::V1::Ping

if ENV['RACK_ENV'] == 'development'
  run Rack::URLMap.new \
    "/" => ApiServer
else
  run ApiServer
end
