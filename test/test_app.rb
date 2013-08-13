require_relative 'helper'

class TestApiServer < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    ApiServer
  end

  context "api_server" do
    context 'on GET /' do
      should "redirect to the enron app" do
        get '/'
        assert_equal 404, last_response.status
      end
    end
  end

end
