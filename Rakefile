ENV["RAILS_ENV"] = 'test'

require 'bundler'

desc "Generates a dummy app for testing"
task :test_app do
  require 'spree/testing_support/common_rake'

  ENV['LIB_NAME'] = 'solidus'
  ENV['DUMMY_PATH'] = 'test_app/dummy'

  Rake::Task["common:test_app"].invoke
  cp 'config/environments/production.rb', 'config/environments/test.rb'
end

task :benchmark do
  benchmarks = Dir['./suite/**/*_benchmark.rb']
  system 'ruby', '-Isuite', *(benchmarks.map{|x| "-r#{x}"}), '-e', ''
end

namespace :benchmark do
  task :all do
    mkdir_p 'data'
    Bundler.with_clean_env do
      databases = ENV.fetch('DATABASES', 'mysql postgres').split(/[ ,]/)
      databases.each do |db|
        branches = ENV.fetch('BRANCHES', 'v1.0 v1.1 v1.2 v1.3 v1.4 v2.1 v2.0 v2.1 v2.3 v2.4 v2.5 v2.6 v2.7 v2.8 master').split(/[ ,]/)
        branches.each do |branch|
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
