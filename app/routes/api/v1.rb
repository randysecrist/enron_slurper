$:.unshift(File.dirname(__FILE__))

# V1 APIs
require 'v1/email'
require 'v1/ping'

# Presents a nicer not found error
class NotFound < Sinatra::Base
end
