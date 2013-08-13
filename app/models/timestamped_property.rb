module Enron
  module Models
    module TimestampedPropertyJson
      def as_json(options={})
        attributes_for_persistence.reject do |k,v|
          %w{ _type }.include? k
        end
      end
    end

    # empty class used for the purpose of inheritance checking
    class TimestampedProperty
    end

    class TimestampedStringProperty < TimestampedProperty
      include Ripple::EmbeddedDocument
      include TimestampedPropertyJson

      property :value, String
      timestamps!
    end

    class TimestampedArrayProperty < TimestampedProperty
      include Ripple::EmbeddedDocument
      include TimestampedPropertyJson

      property :value, Array
      timestamps!
    end

    class TimestampedTimeProperty < TimestampedProperty
      include Ripple::EmbeddedDocument
      include TimestampedPropertyJson

      property :value, Time
      timestamps!
    end
  end
end
