require 'bulkoperation/active_record/batch_update'

module ActiveRecord
    
  class Base

    def optimistic_update
      fail NoPersistentRecord.new if  @new_record
      fail NoOrginalRecordFound.new unless orginal_selected_record

      sql = self.class.build_optimistic_update_sql

      types  = []

      for c in self.class.columns
        type = self.class.to_type_symbol(c)
        types << type
      end

      for c in self.class.columns
        type = self.class.to_type_symbol(c)
        types << type
        types << type if c.null
      end

      binds = self.class.columns.map { |c| read_attribute(c.name) }

      get_optimistic_where_binds.each { |v| binds << v }

      self.class.execute_batch_update(sql, types, [binds])
    end

    def optimistic_delete
      fail NoPersistentRecord.new if @new_record
      fail NoOrginalRecordFound.new unless orginal_selected_record

      sql = self.class.build_optimistic_delete_sql

      binds = get_optimistic_where_binds

      types  = []

      for c in self.class.columns
        type = self.class.to_type_symbol(c)
        types << type
        types << type if c.null
      end

      self.class.execute_batch_update(sql, types, [binds])
    end

    private

    def get_optimistic_where_binds
      binds = []
      self.class.columns.map do |c|
        v = orginal_selected_record[c.name]
        binds << v
        binds << v if c.null
      end

      binds
    end

  end
end
