ENV["RAILS_ENV"] = 'test'

require 'bundler'

desc "Generates a dummy app for testing"
task :test_app do
  require 'spree/testing_support/common_rake'

  ENV['LIB_NAME'] = 'solidus'
  ENV['DUMMY_PATH'] = 'dummy'

  Rake::Task["common:test_app"].invoke
end

task :benchmark do
  sh 'ruby ./benchmark.rb'
end

namespace :benchmark do
  task :all do
    mkdir_p 'data'
    Bundler.with_clean_env do
      %w[mysql postgres].each do |db|
        %w[v1.0 v1.1 v1.2 v1.3 v1.4 v2.0 master].each do |branch|
          ENV['DB'] = db
          ENV['SOLIDUS_BRANCH'] = branch
          sh "bundle update"
          sh "bundle exec rake test_app"
          sh "bundle exec rake benchmark > data/benchmark_#{branch}_#{db}.json"
        end
      end
    end
  end
end
