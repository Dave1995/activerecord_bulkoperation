require "bundler"
Bundler.setup

require 'rake'
require 'rake/testtask'

namespace :display do
  task :notice do
    puts
    puts "To run tests you must supply the adapter, see rake -T for more information."
    puts
  end
end
task :default => ["display:notice"]

#ADAPTERS = %w(mysql mysql2 em_mysql2 jdbcmysql jdbcpostgresql postgresql sqlite3 seamless_database_pool mysqlspatial mysql2spatial spatialite postgis)
ADAPTERS = %w(oracle_enhanced)
ADAPTERS.each do |adapter|
  namespace :test do
    desc "Runs #{adapter} database tests."
    Rake::TestTask.new(adapter) do |t|
      # FactoryGirl has an issue with warnings, so turn off, so noisy
      # t.warning = true
      t.test_files = FileList["test/adapters/#{adapter}.rb", "test/*_test.rb", "test/active_record/*_test.rb", "test/#{adapter}/**/*_test.rb"]
    end
    task adapter
  end
end
