class ActiveRecord::Base

    def self.flush_scheduled_operations(args = {})
        Bulkoperation::ActiveRecord::ScheduledOperations::FlushDirtyObjects.get.flush_record_class(self, args)
    end

    def schedule_merge
        Bulkoperation::ActiveRecord::ScheduledOperations::FlushDirtyObjects.get.add_merge(self)
        self
    end
  
end    