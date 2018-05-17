ENV['RAILS_ENV'] = 'test'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require File.expand_path('../../test_app/dummy/config/environment', __FILE__)
require 'solidus_benchmark'
require 'ffaker'
require 'factory_bot'
FactoryGirl = FactoryBot
require 'spree/testing_support/factories'

ActionController::Base.perform_caching = true
ActionController::Base.allow_forgery_protection = false
Rails.application.config.active_job.queue_adapter = :test

DatabaseCleaner.strategy = :truncation
DatabaseCleaner.clean
