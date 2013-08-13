require_relative '../../helper'
require_relative '../../../app/helpers/ripple'

class Person
  include Ripple::Document
  include Ripple::Document::Finders

  property :name, String
end

class Patient < Person
  include Ripple::Document

  property :middle, String
end

class TestBucketAccess < Test::Unit::TestCase

  context "Ripple::Document::Finders" do
    should "should only include the prefix once" do
      #store
      existing = Ripple.config[:namespace]

      begin
        Ripple.config[:namespace] = 'foo_bar~'
        # Simple Document
        assert_equal 1, Person.bucket_name.scan(Ripple.config[:namespace]).length

        # Document Inheritance w/ EmbeddedDocuments
        assert_equal 1, Patient.bucket_name.scan(Ripple.config[:namespace]).length
      ensure
        # reset
        Ripple.config[:namespace] = existing
      end

    end

    should "do not raise exeception if prefix is not defined" do
      #store
      existing = Ripple.config[:namespace]

      begin
        Ripple.config[:namespace] = nil

        # test
        assert_equal 'people', Patient.bucket_name
      ensure
        # reset
        Ripple.config[:namespace] = existing
      end
    end

  end

end
