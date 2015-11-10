module ActiveRecord
  class Base

    attr_reader :orginal_selected_record

    def save_original      
      @orginal_selected_record = @attributes.to_hash.clone unless @orginal_selected_record
      self
    end

    def callbacks_closed_scheduled_operation
      ( @callbacks_closed_scheduled_operation ||= Set.new)
    end

    def on_closed_scheduled_operation
      @callbacks_closed_scheduled_operation && @callbacks_closed_scheduled_operation.each { |c| c.on_closed_scheduled_operation }
    end

    def unset_new_record
      @new_record = false
    end
    class << self
      # will insert or update the given array
      #
      # +group+ array of activerecord objects
      def merge_group(group, options = {})
        check_group(group)

        to_insert = group.select { |i| i.new_record? }

        to_update = group.select { |i| not i.new_record? }

        affected_rows = 0

        affected_rows += insert_group(to_insert, options) unless to_insert.empty?
        affected_rows += update_group(to_update, options) unless to_update.empty?

        affected_rows
      end      

      def to_type_symbol(column)
        return :string  if  column.sql_type.index('CHAR')
        return :date    if  column.sql_type.index('DATE') or column.sql_type.index('TIMESTAMP')
        return :integer if  column.sql_type.index('NUMBER') and column.sql_type.count(',') == 0
        return :float   if  column.sql_type.index('NUMBER') and column.sql_type.count(',') == 1
        fail ArgumentError.new("type #{column.sql_type} of #{column.name} is unsupported")
      end
      
      def foreign_detail_tables
        @foreign_detail_tables ||= find_foreign_detail_tables(table_name)
      end

      def foreign_master_tables
        @foreign_master_tables ||= find_foreign_master_tables(table_name)
      end
      private

      def check_group(group)
        fail ArgumentError.new("Array expected. Got #{group.class.name}.") unless group.is_a? Array or group.is_a? Set or group.is_a? ActiveRecord::Relation
        fail ArgumentError.new("only records of #{name} expected. Unexpected #{group.select { |i| not i.is_a? self }.map { |i|i.class.name }.uniq.join(',') } found.") unless group.select { |i| not i.is_a? self }.empty?
      end

      def insert_group(group, options = {})
        to_insert = group.select { |i| not i.new_record? }

        sql = "INSERT INTO #{table_name} " \
              '( ' +
              "#{columns.map { |c| c.name }.join(', ') } " +
              ') VALUES ( ' +
              "#{(1..columns.count).map { |i| ":#{i}"  }.join(', ') } " +
              ')'

        types  = []

        for c in columns
          type = to_type_symbol(c)
          types << type
        end

        values = []

        for record in group

          row = []

          for c in columns
            v = record.read_attribute(c.name)
            row << v
          end

          values << row

        end

        result = execute_batch_update(sql, types, values)

        group.each { |r| r.unset_new_record }

        result
      end

      def update_group(group, options = {})
        check_group(group)

        optimistic = options[:optimistic]
        optimistic = true if optimistic.nil?

        fail NoOrginalRecordFound.new("#{name} ( #{table_name} )") if optimistic and not group.select { |i| not i.orginal_selected_record }.empty?

        sql = optimistic ? build_optimistic_update_sql : build_update_by_primary_key_sql

        types  = []

        for c in columns
          type = to_type_symbol(c)
          types << type
        end

        if optimistic

          for c in columns
            type = to_type_symbol(c)
            types << type
            types << type if c.null
          end

        else

          keys = primary_key_columns

          for c in keys
            type = to_type_symbol(c)
            types << type
          end

        end

        values = []

        keys = primary_key_columns

        for record in group
          row = []

          for c in columns
            v = record.read_attribute(c.name)
            row << v
          end

          if optimistic

            orginal = record.orginal_selected_record            
            for c in columns

              v = orginal[ c.name]
              row << v
              row << v if c.null

            end

          else

            keys.each { |c| row << record[ c.name] }

          end

          values << row

        end

        count = execute_batch_update(sql, types, values, optimistic)

        count
      end

      public
      def insert_on_missing_group( keys, group, options = {} )

        #fail 'the give key array is empty' if keys.empty?

        keys = Array( primary_key ) if keys.nil? || keys.empty?

        sql ="  
        merge into #{table_name} target 
        using ( select #{columns.map{|c| ":#{columns.index(c)+1} #{c.name}" }.join(', ')} from dual ) source 
        on ( #{keys.map{|c| "target.#{c} = source.#{c}" }.join(' and ')}  ) 
        when not matched then 
        insert ( #{columns.map{|c| c.name }.join(', ')} )  
        values( #{columns.map{|c| "source.#{c.name}" }.join(', ')} )
        "


        types = columns.map{ |c| to_type_symbol(c) }

        values = []

        for record in group

          row = []

          for c in columns
            v = record.read_attribute(c.name)
            row << v
          end

          values << row

        end

        begin
          result = execute_batch_update(sql, types, values,false)
        rescue  => e
          raise ActiveRecord::StatementInvalid.new( "#{e.message}\n#{sql}" )
        end

        group.each { |r| r.unset_new_record }

        result

      end
      
      def delete_group(group, options = {})
        check_group(group)

        optimistic = options[:optimistic]
        optimistic = true if optimistic.nil?

        to_delete = group.select { |i| not i.new_record? }

        fail NoOrginalRecordFound.new if optimistic and not to_delete.select { |i| not i.orginal_selected_record }.empty?

        sql = optimistic ? build_optimistic_delete_sql : build_delete_by_primary_key_sql

        types  = []

        if optimistic

          for c in columns
            type = to_type_symbol(c)
            types << type
            types << type if c.null
          end

        else

          keys = primary_key_columns

          for c in keys
            type = to_type_symbol(c)
            types << type
          end

        end

        values = []

        if optimistic

          for record in to_delete
            row = []
            orginal = record.orginal_selected_record
            for c in columns

              v = orginal[  c.name]
              row << v
              row << v if c.null

            end

            values << row

          end

        else

          keys = primary_key_columns

          for record in to_delete
            row = keys.map { |c| record[ c.name] }
            values << row
          end

        end

        count = execute_batch_update(sql, types, values, optimistic)

        count

      rescue ExternalDataChange => e
        raise e
      rescue Exception => e
        raise StatementError.new("#{sql} #{e.message}")
      end

    end
  end
end
