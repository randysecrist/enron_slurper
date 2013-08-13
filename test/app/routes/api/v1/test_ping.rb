require_relative '../../../../helper'

class TestV1Ping < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    API::V1::Ping
  end

  context "GET /ping" do
    setup do
    end

    should "return HTTP 204 when up and running" do
      get "/v1/ping"

      assert_equal 204, last_response.status
    end

    should "return HTTP 200 PONG when up and running" do
      get "/v1/ping/ping"

      assert_equal 200, last_response.status
      assert_equal "PONG", last_response.body
    end

    should "return HTTP 204 when backend is up and running" do
      get "/v1/ping/backend"

      assert_equal 204, last_response.status
    end


    should "return HTTP 503 when backend is not running or no data returned" do
      config = Ripple.config
      begin
        Ripple.config = {:host=>"not_an_ip", :namespace=>"test_ns~"}
        get "/v1/ping/backend"
        assert_equal 503, last_response.status
      ensure
        Ripple.config = config
      end
    end
  end
end
