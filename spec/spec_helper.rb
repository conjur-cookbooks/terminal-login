require 'chefspec'
require 'rspec/its'

RSpec.configure do |config|
  config.cookbook_path = [ File.expand_path('../.vendor', File.dirname(__FILE__)) ]
end
