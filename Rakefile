ENV["RAILS_ENV"] = 'test'

$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'spree/testing_support/common_rake'

desc "Generates a dummy app for testing"
task :test_app do
  ENV['LIB_NAME'] = 'solidus'
  ENV['DUMMY_PATH'] = 'dummy'

  Rake::Task["common:test_app"].invoke
end

task :benchmark do
  load './benchmark.rb'
end
