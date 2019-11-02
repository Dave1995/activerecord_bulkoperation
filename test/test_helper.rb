require "rubygems"
require 'pathname'
test_dir = Pathname.new File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "fileutils"

ENV["RAILS_ENV"] = "test"

require "bundler"
Bundler.setup
Bundler.require

require "active_record"
require "active_record/fixtures"
require "active_support/test_case"

require 'active_support/testing/autorun'
require "mocha/test_unit"

ActiveSupport::TestCase.test_order = :sorted
adapter = ENV["DB_ADAPTER"] || "oracle_enhanced"

FileUtils.mkdir_p 'log'
ActiveRecord::Base.logger = Logger.new("log/test.log")
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Base.configurations['test'] = YAML.load(ERB.new(File.read(test_dir.join("database.yml"))).result)[adapter]
ActiveRecord::Base.default_timezone = :utc

require "activerecord_bulkoperation"

ActiveRecord::Base.establish_connection :test

#ActiveSupport::Notifications.subscribe(/active_record.sql/) do |event, _, _, _, hsh|
#  ActiveRecord::Base.logger.info hsh[:sql]
#end

require test_dir.join("schema/generic_schema")

Dir[File.dirname(__FILE__) + "/models/*.rb"].each{ |file| require file }
