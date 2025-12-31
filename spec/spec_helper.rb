require 'bundler/setup'
require 'rspec'
require_relative '../lib/program'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.order = :defined
end
