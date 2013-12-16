$:.unshift(File.join(File.dirname(__FILE__), '..'))
$:.unshift(File.dirname(__FILE__))

ENV['RACK_ENV'] = 'test'
ROOT_TEST = File.expand_path(File.dirname(__FILE__))

require 'minitest/unit'
require 'simplecov'
require 'faker'
SimpleCov.start do
  project_name "API Server"

  add_filter "app/app.rb"
  add_filter "/test/"

  add_group "Helpers", "app/helpers"
  add_group "Middleware", "app/middleware"
  add_group "Models", "app/models"
  add_group "Modules", "lib"
  add_group "Routes", "app/routes"
  add_group "Workers", "app/workers"
end

require 'rack/test'
require 'shoulda'
require 'pathname'
require 'mock_redis'
require 'mocha'

# fire up test server before loading app
require 'ripple'
require 'test/support/ripple_test_server'
Ripple.load_config(File.join('config','ripple.yml'), [ENV['RACK_ENV']])
puts 'Setting up Temporary Database ...'
Ripple::TestServer.setup
success = false
# these execute in reverse order on exit
at_exit { exit! success }
at_exit { puts 'API Suite Tear Down' }
at_exit {
  # Spit out coverage stats.
  SimpleCov.result.format!
}
at_exit do
  unless $! || Test::Unit.run?
    success = Test::Unit::AutoRunner.run
    Ripple::TestServer.destroy unless Ripple.config[:retain_test_server] = true
    success
  end
end
at_exit { puts 'Starting API Tests ...' }
puts 'Loading Application ...'

require 'app/app'

# allow riak test client connections
require 'webmock'
WebMock.disable_net_connect! allow_localhost: true, allow: ["#{Ripple.config[:host]}:#{Ripple.config[:http_port]}"]

FIXTURES_PATH = Pathname.new(File.join(ROOT_DIR,'test','support','fixtures'))

# mock redis
Resque.redis = MockRedis.new

class Test::Unit::TestCase
  include Rack::Test::Methods

  def valid_user_details
    @user_data =  {
      :name => Faker::Name.name,
      :gender => 'm',
      :locale => "#{Faker::Address.city}, #{Faker::Address.state_abbr}",
      :email => Faker::Internet.email,
      :phone_numbers =>[Faker::PhoneNumber.phone_number, Faker::PhoneNumber.cell_phone],
      :birthdate => '2013-07-30T11:21:24Z',
      :sources => []
    }
  end

  def assert_starts_with(expected, actual)
    assert !(actual.match /^#{expected}/).nil?, "Expected " + actual + " to start with " + expected
  end
end
