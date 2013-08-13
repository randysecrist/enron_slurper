require_relative '../../helper'

module Enron
  module Models
    class UserTest < Test::Unit::TestCase
      context "user" do
        setup do
        end

        teardown do
          $test_server.recycle
        end

        should "create new user" do
          user = Enron::Models::User.new
          assert user.save, user.errors.to_s
        end
      end
    end
  end
end
