source 'https://rubygems.org'

gem 'rake'
gem 'sinatra'
gem 'rack-contrib'
gem 'i18n'
gem 'emk-sinatra-url-for'
gem 'json', '~> 1.7'

# Encryption Deps
gem 'ripple-encryption', '~> 0.0.4'
gem 'commander'
gem 'pbkdf2-peter_v'

gem 'faraday', '~> 0.8.7'
gem 'hashie'

gem 'rack', '1.5.2'
gem 'unicorn', '4.6.2'

gem 'maruku', '0.6.1'  # this version of maruku fix historical fault for the iconv message seen on stderr
gem 'jekyll'
gem 'resque'

gem 'settings'
gem 'log4r'

# DB
gem 'riak-client', '~> 1.1.1'
gem 'ripple', :git => 'git://github.com/basho/ripple.git', :ref => '913806aa2942db5a3b61d1432d2c9be200338f50'
gem 'excon',     '~> 0.16.4'
gem 'yajl-ruby', '~> 1.1.0', :require => 'yajl/json_gem'

gem 'mail'


group :development, :test do
  gem 'random_data'
  gem 'sinatra-reloader'
  gem 'simplecov'

  # for docs
  gem 'yard'
  gem 'rdiscount'

  # profiling
  gem 'ruby-prof'

  # debugging
  gem 'debugger'
end

group :test do
  gem 'minitest'
  gem 'rack-test'
  gem 'webmock', '1.11.0'
  gem 'shoulda'
  gem 'vcr'
  gem 'mocha', '0.11.3'

  # make testing easier
  gem 'guard'
  gem 'guard-test'
  require 'rbconfig'
end
