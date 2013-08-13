module Ripple
  module MapredFinder
    class Error < StandardError; end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # overwrite find to intercept fetching an array
      def find(args)
        use_mapred = ApiServer.setting(:enable_mapred)
        if args.is_a?(Array) && args.length > 1 && use_mapred
          self.fetch_all args
        else
          super
        end
      end

      # bulk key fetch using mapreduce.
      # @param [Array] array of keys to lookup
      def fetch_all(keys)
        begin
          return using_patched_mapred(keys)
        rescue
          return using_vanilla_mapred(keys)
        end
      end

      private

      # replace this once riak map_identity is fixed
      # this code path is correct on any riak cluster which has the enron_map_reduce patch
      def using_patched_mapred(keys)
        mapred = Riak::MapReduce.new(Ripple.client)
        keys.each do |key|
          mapred.add self.bucket_name, key
        end

        mapred_module = 'enron_map_reduce'
        mapred_fun = 'map_key_value'
        mapred.map([mapred_module, mapred_fun], :arg => 'filter_notfound', :keep => true, :language => :erlang)
        begin
          results = mapred.run
        rescue Riak::HTTPFailedRequest => e
          # will occur if patch is not installed
          raise e
        rescue Riak::MapReduceError => e
          $stderr.puts "MapRed execution problem: #{e.message}"
          $stderr.puts e.inspect
          raise e
        end

        # return the empty set if no results were found
        results.reject!{|r| r == ""}
        return [] if results.nil?

        # instantiate Ripple objects
        # results spec: [[Key, <<"Siblings">>]]
        encryption_on = ApiServer.setting(:enable_encryption) && self.include?(Ripple::Encryption)
        content_type = (encryption_on) ? 'application/x-json-encrypted' : 'application/json'
        rtnval = results.map do |result|
          key = result[0]
          value = result[1]
          robject = OpenStruct.new(:raw_data => value)
          robject = Riak::Bucket.new(Ripple.client, self.bucket_name).new
          robject.content_type = content_type
          robject.raw_data = value
          robject.key = key
          document = self.send(:instantiate, robject)
        end
        return rtnval
      end

      # the following is defective for clusters of size > 1
      # it is left here for compatibility with vagrant and development environments
      # note, once map_identity is fixed, only one code path will remain
      def using_vanilla_mapred(keys)
        mapred = Riak::MapReduce.new(Ripple.client)
        keys.each do |key|
          mapred.add self.bucket_name, key
        end

        mapred.map(['riak_kv_mapreduce', 'map_object_value'], :arg => 'filter_notfound', :keep => true, :language => :erlang)
        begin
          results = mapred.run
        rescue Riak::MapReduceError => e
          $stderr.puts "MapRed execution problem: #{e.message}"
          $stderr.puts e.inspect
          raise e
        end

        # return the empty set if no results were found
        results.reject!{|r| r == ""}
        return [] if results.nil?

        # instantiate Ripple objects
        encryption_on = ApiServer.setting(:enable_encryption) && self.include?(Ripple::Encryption)
        content_type = (encryption_on) ? 'application/x-json-encrypted' : 'application/json'
        cnt = 0
        rtnval = results.map do |value|
          robject = OpenStruct.new(:raw_data => value)
          robject = Riak::Bucket.new(Ripple.client, self.bucket_name).new
          robject.content_type = content_type
          robject.raw_data = value
          robject.key = keys[cnt] # unreliable on riak clusters > 1
          cnt += 1
          document = self.send(:instantiate, robject)
        end
        return rtnval
      end
    end
  end
end
