ENV["RAILS_ENV"] = 'test'

$LOAD_PATH << File.expand_path('../lib', __FILE__)

require 'generators/spree/install/install_generator'
require 'generators/spree/dummy/dummy_generator'

desc "Generates a dummy app for testing"
task :test_app do
  ENV['DUMMY_PATH'] = 'dummy'

  # --lib-name=rails is a hack to require nothing
  Spree::DummyGenerator.start ["--lib-name=rails", "--quiet"]
  Spree::InstallGenerator.start ["--auto-accept", "--migrate=true", "--seed=false", "--sample=false", "--quiet"]
end

task :benchmark do
  load './benchmark.rb'
end
