module ActiveRecord
  module Bulkoperation
    module AbstractAdapter
      module InstanceMethods

        def self.included(base)
          base.class_eval do
            alias_method :commit_db_transaction_without_callback, :commit_db_transaction
            alias_method :rollback_db_transaction_without_callback, :rollback_db_transaction
            alias_method :rollback_to_savepoint_without_callback, :rollback_to_savepoint
            alias_method :create_savepoint_without_callback, :create_savepoint

            def commit_db_transaction
              # AKu a copy of the listener array is required, because the listener can remove can modify the array
              connection_listeners.select{|l| l.respond_to?('before_commit') }.each{|l| l.before_commit}

              commit_db_transaction_without_callback

              # AKu a copy of the listener array is required, because the listener can remove can modify the array
              connection_listeners.select{|l| l.respond_to?('after_commit') }.each{|l| l.after_commit}

            end
            
            def rollback_db_transaction
              rollback_db_transaction_without_callback
              # AKu a copy of the listener array is required, because the listener can remove can modify the array
              connection_listeners.select{|l| l.respond_to?('after_rollback') }.each{|l| l.after_rollback}
            end
                    
            def rollback_to_savepoint(name = current_savepoint_name)
              rollback_to_savepoint_without_callback(name)
              # AKu a copy of the listener array is required, because the listener can remove can modify the array
              connection_listeners.select{|l| l.respond_to?('after_rollback_to_savepoint') }.each{|l| l.after_rollback_to_savepoint}
            end
                    
            def create_savepoint(name = current_savepoint_name)
              # AKu a copy of the listener array is required, because the listener can remove can modify the array
              connection_listeners.select{|l| l.respond_to?('before_create_savepoint') }.each{|l| l.before_create_savepoint}
              create_savepoint_without_callback(name)
            end
          end
        end

        def connection_listeners
          @connection_listeners ||= []
        end
         
      end
    end
  end  
end
