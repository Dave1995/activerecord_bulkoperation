module ActiveRecord
  module Bulkoperation
    AdapterPath = 'activerecord_bulkoperation/active_record/adapters'

    def self.base_adapter(adapter)
      case adapter
      when 'mysqlspatial' then 'mysql'
      when 'mysql2spatial' then 'mysql2'
      when 'spatialite' then 'sqlite3'
      when 'oracle_enhanced' then 'oracle_enhanced'
      else adapter
      end
    end

    # Loads the import functionality for a specific database adapter
    def self.require_adapter(adapter)
      require File.join(AdapterPath,'/abstract_adapter')
      begin
        require File.join(AdapterPath,"/#{base_adapter(adapter)}_adapter")
      rescue LoadError
        # fallback
      end
    end

    # Loads the import functionality for the passed in ActiveRecord connection
    def self.load_from_connection_pool(connection_pool)
      require_adapter connection_pool.spec.config[:adapter]
    end
  end
end

# if MRI or YARV
puts "RUBY_ENGINE=#{RUBY_ENGINE}, ORACLE_ENHANCED_CONNECTION=#{ORACLE_ENHANCED_CONNECTION}"
if !defined?(RUBY_ENGINE) || RUBY_ENGINE == 'ruby'
  ORACLE_ENHANCED_CONNECTION = :oci
  require 'activerecord_bulkoperation/connection_adapters/oracle_enhanced/oci_connection'
# if JRuby
elsif RUBY_ENGINE == 'jruby'
  ORACLE_ENHANCED_CONNECTION = :jdbc
  require 'activerecord_bulkoperation/connection_adapters/oracle_enhanced/jdbc_connection'
else
  raise "Unsupported Ruby engine #{RUBY_ENGINE}"
end

require 'activerecord_bulkoperation/bulkoperation'
require 'activerecord_bulkoperation/active_record/associations/associations'
require 'activerecord_bulkoperation/group_operations'
require 'activerecord_bulkoperation/util/sequence_cache'
require 'activerecord_bulkoperation/util/entity_hash'
require 'activerecord_bulkoperation/util/transaction_object'
require 'activerecord_bulkoperation/util/flush_dirty_objects'

