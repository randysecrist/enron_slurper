module Enron
  module Models
    class User
      include Ripple::Document
      include Ripple::Encryption

      # @return [String] status (active / inactive) of user
      one :status,         class_name: 'TimestampedStringProperty'
      # @return [String] name of user
      one :name,           class_name: 'TimestampedStringProperty'
      # @return [String] gender of user
      one :gender,         class_name: 'TimestampedStringProperty'
      # @return [String] locale of user
      one :locale,         class_name: 'TimestampedStringProperty'
      # @return [String] website of user
      one :link,           class_name: 'TimestampedStringProperty'
      # @return [String] email of user
      one :email,          class_name: 'TimestampedStringProperty'
      # @return [String] timezone of user
      one :timezone,       class_name: 'TimestampedStringProperty'
      # @return [Array] list of user phone numbers
      one :phone_numbers,  class_name: 'TimestampedArrayProperty'
      # @return [Time] birthday and time of user
      one :birthdate,      class_name: 'TimestampedTimeProperty'
      # @return [String] height of user
      one :height,         class_name: 'TimestampedStringProperty'
      # @return [String] race of user
      one :race,           class_name: 'TimestampedStringProperty'
      # @return [String] hair color of user
      one :hair_color,     class_name: 'TimestampedStringProperty'
      # @return [String] eye color of user
      one :eye_color,      class_name: 'TimestampedStringProperty'
      # @return [String] blood type of user
      one :blood_type,     class_name: 'TimestampedStringProperty'
      # @return [String] shoe size of user
      one :shoe_size,      class_name: 'TimestampedStringProperty'

      # Deprecated
      # These are remained defined in the model to ensure that any old
      # user profiles that may have these properties defined don't
      # break the application
      # @return [String] first name of user
      one :first_name,     class_name: 'TimestampedStringProperty'
      # @return [String] last name of user
      one :last_name,      class_name: 'TimestampedStringProperty'
      # @return [String] user description
      one :bio,            class_name: 'TimestampedStringProperty'

      # @return [Array] of Enron::Models::Source objects associated with user
      # many :sources

      def self.find_or_create(user_key)
        unless user = find(user_key)
          user = new
          user.key = user_key
          user.save
        end
        user
      end

      def initialize(user_data = { })
        timestamped_user_data = timestampify_attributes(user_data)
        super timestamped_user_data
      end

      def update_attributes(user_data = { })
        timestamped_user_data = timestampify_attributes(user_data)
        super timestamped_user_data
      end

      def raw_attributes=(new_raw_attributes = { })
        timestamped_raw_attributes =
          timestampify_attributes(new_raw_attributes)
        super timestamped_raw_attributes
      end

      def timestampify_attributes(user_data)
        timestamped_data = { }
        user_data.each do |k,v|
          value_looks_timestamped = v.is_a?(Hash) &&
            (v['created_at'] || v[:created_at])
          begin
            candidate = send(k.to_sym).build
            if candidate.is_a?(TimestampedProperty) && !value_looks_timestamped
              candidate.value = v
              timestamped_data[k] = candidate
            else
              timestamped_data[k] = v
            end
          rescue NoMethodError
            timestamped_data[k] = v
          end
        end
        return timestamped_data
      end

      # Defines JSON representation
      # @param [Hash] options (ignored)
      # @return [String] JSONified version of the instance
      def as_json(options = {})
        onesies = self.class.embedded_associations.select { |a| a.type == :one }
        rtnval = onesies.inject({}) do |hsh, a|
          unless [:bio, :first_name, :last_name].include? a.name
            d = instance_variable_get(a.ivar)
            hsh[a.name] = d.as_json(options)
          end
          hsh[:id] = self.key # return unique identifier for user
          hsh
        end
        usage = {usage: self.usage} rescue Hash.new
        rtnval.merge(usage)
      end

    end
  end
end
