module ActiveRecord

    module Persistence
      module ClassMethods
  
          alias_method :instantiate_without_save_original, :instantiate
  
          def instantiate(attributes, column_types = {})
            record = instantiate_without_save_original(attributes, column_types)
            record.save_original
            record
          end
      end
    end

end