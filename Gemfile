source 'https://rubygems.org'

#gemspec

version = ENV['AR_VERSION'] || "4.2"

if version > "4.0"
  gem "minitest"
end

gem 'mocha'

eval_gemfile File.expand_path("../gemfiles/#{version}.gemfile", __FILE__)
