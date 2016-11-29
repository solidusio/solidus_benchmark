ENV['RAILS_ENV'] = 'test'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require File.expand_path('../../test_app/dummy/config/environment', __FILE__)
require 'solidus_benchmark'
require 'ffaker'
require 'spree/testing_support/factories'
