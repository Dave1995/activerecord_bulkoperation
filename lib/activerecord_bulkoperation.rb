class ActiveRecord::Base
  class << self
    def establish_connection_with_activerecord_bulkoperation(*args)
      establish_connection_without_activerecord_bulkoperation(*args)
      ActiveSupport.run_load_hooks(:active_record_connection_established, connection_pool)
    end
    alias_method_chain :establish_connection, :activerecord_bulkoperation
  end
end

ActiveSupport.on_load(:active_record_connection_established) do |connection_pool|
  if !ActiveRecord.const_defined?(:Bulkoperation, false) || !ActiveRecord::Bulkoperation.respond_to?(:load_from_connection_pool)
    require 'activerecord_bulkoperation/base'
  end

  ActiveRecord::Bulkoperation.load_from_connection_pool connection_pool
end
