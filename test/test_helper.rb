require "rubygems"
require 'pathname'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "fileutils"

ENV["RAILS_ENV"] = "test"

require "bundler"
Bundler.setup

require "active_record"
require "active_record/fixtures"
require "active_support/test_case"
require 'active_support/testing/autorun'

ActiveSupport::TestCase.test_order = :sorted

ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Base.configurations['test'] = YAML.load_file( __dir__+ '/database.yml')['oracle_enhanced']
ActiveRecord::Base.default_timezone = :utc

require "activerecord_bulkoperation"

ActiveRecord::Base.establish_connection :test

#ActiveSupport::Notifications.subscribe(/active_record.sql/) do |event, _, _, _, hsh|
#  ActiveRecord::Base.logger.info hsh[:sql]
#end

require __dir__ + '/schema/generic_schema'

Dir[File.dirname(__FILE__) + "/models/*.rb"].each{ |file| require file }

require 'bulkoperation/bulkoperation'
require 'bulkoperation/active_record/connection_listeners'
require 'bulkoperation/active_record/scheduled_operations'
require 'bulkoperation/active_record/sequences'
require 'bulkoperation/active_record/group_select'
require 'bulkoperation/active_record/batch_update'
require 'bulkoperation/active_record/optimistic_locking'