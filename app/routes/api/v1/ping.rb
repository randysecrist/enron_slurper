module API
  module V1
    class Ping < Sinatra::Base
      register Enron::API

      version 'v1'
      prefix '/ping'

      before do
        content_type 'text/plain'
      end

      get "/" do
        status 204
      end

      get '/backend' do
        uri = "http://#{Ripple.config[:host]}:#{Ripple.config[:http_port]}/buckets/not_a_bucket/keys/not_a_key"
        begin
          client = Faraday.new(url: uri)
          response = client.get ''
        rescue
          halt 503, "Configuration | Connectivity Error"
        end

        if response.status == 404
          status 204
        else
          halt 503, response.body
        end
      end

      get '/ping' do
        status 200
        body "PONG"
      end

    end
  end
end
