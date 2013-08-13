module Enron
  module Models
    class Document
      include Enron::Models
      include Ripple::Document
      include Ripple::Encryption

      attr_accessor :input

      property :user_key, String, presence: true, index: true
      property :document_key, String, presence: true
      property :document_size, Integer, presence: true
      property :document_type, String, presence: true
      property :document_checksum, String, presence: true
      timestamps!

      one :user, using: :stored_key

      UNIT_SEPARATOR = "\x1f"

      def initialize(input=nil, params={})
        @input = input
        super params
      end

      def key
        delimiter = UNIT_SEPARATOR
        [user_key, document_key].join delimiter
      end

      index :user_document, String do
        [user_key, document_key].join UNIT_SEPARATOR
      end

      def self.find_by_user_and_document(user_key, document_key)
        find_by :user_document, [user_key, document_key].join(UNIT_SEPARATOR)
      end

      after_save :add_document_to_x
      after_destroy :remove_document_from_x

      def add_document_to_x
        # add key to some other object
      end

      def remove_document_from_x
        # remove key to some other object
      end

      def self.find_document(meta_key)
        meta = find meta_key
        return nil if meta.nil?
        document = Enron::Models::DocumentValue.find(meta_key)
        return meta[:document_type], document
      end

      def save!
        return false if @input.nil?
        document_value = Enron::Models::DocumentValue.new({
          key: key,
          value: @input,
          type: document_type,
        })
        super && document_value.save!
      end

      def destroy
        Enron::Models::DocumentValue.delete(key) && super
      end

      private
    end

    class DocumentValue
      attr_accessor :document_key, :document_type, :document

      def initialize(params={})
        key = params[:key]
        content_type = params[:type]

        uri = self.class.build_uri(key)
        @header = { 'Content-Type' => content_type }

        @value = params[:value]

        if Ripple::Encryption.activated?
          @value = Riak::Serializers['application/x-binary-encrypted'].dump @value
          @header['X-Riak-Meta-Encryption-version'] = @value[:version]
          @header['X-Riak-Meta-Encryption-iv'] = @value[:iv]
        end

        @client = Faraday.new(url: uri, headers: @header)
      end

      def save!
        if Ripple::Encryption.activated?
          response = @client.put '', @value[:data]
        else
          response = @client.put '', @value
        end
        response.status == 204
      end

      def self.find(key)
        uri = build_uri(key)
        client = Faraday.new(url: uri)
        response = client.get ''
        content_type = response.headers['content-type']
        version = response.headers['x-riak-meta-encryption-version']
        iv = response.headers['x-riak-meta-encryption-iv']

        unless iv.nil?
          data = { version: version, iv: iv, data: response.body }
          return Riak::Serializers['application/x-binary-encrypted'].load data
        end
        response.body
      end

      def self.delete(key)
        uri = build_uri(key)
        client = Faraday.new(url: uri)
        response = client.delete ''
        response.status
      end

      def self.build_uri(key)
        bucket = "#{Ripple.config[:namespace]}e_nova_models_document_values"
        URI.encode "http://#{Ripple.config[:host]}:#{Ripple.config[:http_port]}/riak/#{bucket}/#{key}"
      end

    end
  end
end

