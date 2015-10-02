module ActiveRecord
  module Bulkoperation
    module Util    
      class TransactionObject
        def self.get
          result = ActiveRecord::Base.connection.connection_listeners.select { |l| l.class == self }.first
          unless result
            result = new
            ActiveRecord::Base.connection.connection_listeners << result
          end
          result
        end

        def after_commit
          close
          ActiveRecord::Base.connection.connection_listeners.delete(self)
        end

        def after_rollback
          close
          ActiveRecord::Base.connection.connection_listeners.delete(self)
        end

        def after_rollback_to_savepoint
        end

        def close
        end
      end
    end
  end
end