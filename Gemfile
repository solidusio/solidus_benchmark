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
gem 'factory_girl'

gem 'sqlite3'
gem 'pg'
gem 'mysql2'

gem 'stackprof'
gem 'flamegraph'
