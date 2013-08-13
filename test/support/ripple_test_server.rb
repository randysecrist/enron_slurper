require 'riak/test_server'
require 'singleton'

class RiakNotFound < StandardError; end

module Ripple
  # Extends the {Riak::TestServer} to be aware of the Ripple
  # configuration and adjust settings appropriately. Also simplifies
  # its usage in the generation of test helpers.
  class TestServer < Riak::TestServer
    include Singleton
    attr_accessor :remote

    # Creates and starts the test server
    def self.setup
      unless instance.remote
        instance.recreate
        instance.start
      end
    end

    def self.clear
      unless instance.remote
        instance.drop
      end
    end

    def self.destroy
      unless instance.remote
        instance.destroy
      end
    end

    def find_riak
      dir = ENV['RIAK_BIN_DIR'] || ENV['PATH'].split(':').detect { |dir| File.exists?(dir+'/riak') }
      unless dir
        raise RiakNotFound.new <<-EOM

You must have riak installed and in your path to run the tests
or you can define the environment variable RIAK_BIN_DIR to
tell the tests where to find RIAK_BIN_DIR. For example:

    export RIAK_BIN_DIR=/path/to/riak/bin

      EOM
        exit 1
      end
      return dir
    end

    @private
    def initialize(options=Ripple.config.dup)
      if Ripple.config[:host] == "127.0.0.1"
        options[:env] ||= {}
        options[:env][:riak_kv] ||= {}
        if js_source_dir = Ripple.config.delete(:js_source_dir)
          options[:env][:riak_kv][:js_source_dir] ||= js_source_dir
        end
        options[:env][:riak_kv][:allow_strfun] = true
        options[:env][:riak_kv][:map_cache_size] ||= 0
        options[:env][:riak_core] ||= {}
        options[:env][:riak_core][:http] ||= [ Tuple[Ripple.config[:host], Ripple.config[:http_port]] ]
        options[:env][:riak_core][:handoff_port] ||= Ripple.config[:handoff_port]
        options[:env][:riak_kv][:pb_port] ||= Ripple.config[:pb_port]
        options[:env][:riak_kv][:pb_ip] ||= Ripple.config[:host]
        options[:root] ||= (ENV['RIAK_TEST_PATH'] || '/tmp/.enron_api.riak')
        options[:source] ||= find_riak
        options[:env][:riak_core][:slide_private_dir] ||= options[:root] + '/slide-data'
        super(options)
        @env[:riak_kv][:http_url_encoding] = :on
      else
        @remote = true
      end
    end
  end
end

class TestServerShim
  def recycle
    Ripple::TestServer.clear
  end
end

$test_server = TestServerShim.new
