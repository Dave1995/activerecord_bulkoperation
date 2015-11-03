require 'activerecord_bulkoperation/adapters/oracle_enhanced_adapter'

module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class OracleEnhancedAdapter # :nodoc:
      include ActiveRecord::Bulkoperation::OracleEnhancedAdapter
      include ActiveRecord::Bulkoperation::AbstractAdapter::InstanceMethods
    end
  end
end
