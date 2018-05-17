source 'https://rubygems.org'

solidus_branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
solidus_ref = ENV['SOLIDUS_REF']
solidus_path = ENV['SOLIDUS_PATH']
if solidus_path
  gem "solidus", path: solidus_path
elsif solidus_ref
  gem "solidus", git: "https://github.com/solidusio/solidus.git", ref: solidus_ref
else
  gem "solidus", git: "https://github.com/solidusio/solidus.git", branch: solidus_branch
end

gem 'pry'
gem 'database_cleaner'
gem 'factory_bot'
gem 'rack-test'

gem 'sqlite3'
gem 'mysql2', '~> 0.4.10', require: false
gem 'pg', '~> 0.21', require: false

gem 'stackprof'
gem 'flamegraph'
gem 'ffaker'
