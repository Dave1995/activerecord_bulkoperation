# frozen_string_literal: true

module ActiveRecord
  class Base
    attr_reader :orginal_selected_record

    def save_original
      unless defined?(@orginal_selected_record) && @orginal_selected_record
        @orginal_selected_record = @attributes.to_hash.clone
      end
      self
    end

    def callbacks_closed_scheduled_operation
      (@callbacks_closed_scheduled_operation ||= Set.new)
    end

    def on_closed_scheduled_operation
      defined?(@callbacks_closed_scheduled_operation) && @callbacks_closed_scheduled_operation && @callbacks_closed_scheduled_operation.each(&:on_closed_scheduled_operation)
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

        to_insert = group.select(&:new_record?)

        to_update = group.reject(&:new_record?)

        affected_rows = 0

        unless to_insert.empty?
          affected_rows += insert_group(to_insert, options)
        end
        unless to_update.empty?
          affected_rows += update_group(to_update, options)
        end

        affected_rows
      end

      def to_type_symbol(column)
        return :string if column.sql_type.index('CHAR')
        if column.sql_type.index('DATE') || column.sql_type.index('TIMESTAMP')
          return :date
        end
        if column.sql_type.index('NUMBER') && (column.sql_type.count(',') == 0)
          return :integer
        end
        if column.sql_type.index('NUMBER') && (column.sql_type.count(',') == 1)
          return :float
        end

        raise ArgumentError, "type #{column.sql_type} of #{column.name} is unsupported"
      end

      def foreign_detail_tables
        @foreign_detail_tables ||= find_foreign_detail_tables(table_name)
      end

      def foreign_master_tables
        @foreign_master_tables ||= find_foreign_master_tables(table_name)
      end

      def check_group(group)
        unless group.is_a?(Array) || group.is_a?(Set) || group.is_a?(ActiveRecord::Relation)
          raise ArgumentError, "Array expected. Got #{group.class.name}."
        end
        unless group.reject { |i| i.is_a? self }.empty?
          raise ArgumentError, "only records of #{name} expected. Unexpected #{group.reject { |i| i.is_a? self }.map { |i| i.class.name }.uniq.join(',')} found."
        end
      end

      def insert_group(group, _options = {})
        group.reject(&:new_record?)

        sql = "INSERT INTO #{table_name} " \
              '( ' \
              "#{columns.map(&:name).join(', ')} " \
              ') VALUES ( ' \
              "#{(1..columns.count).map { |i| ":#{i}" }.join(', ')} " \
              ')'

        types = []

        columns.each do |c|
          type = to_type_symbol(c)
          types << type
        end

        values = []

        group.each do |record|
          row = []

          columns.each do |c|
            v = record.read_attribute(c.name)
            row << v
          end

          values << row
        end

        result = execute_batch_update(sql, types, values)

        group.each(&:unset_new_record)

        result
      end

      def update_group(group, options = {})
        check_group(group)

        optimistic = options[:optimistic]
        optimistic = true if optimistic.nil?

        if optimistic && !group.reject(&:orginal_selected_record).empty?
          raise NoOrginalRecordFound, "#{name} ( #{table_name} )"
        end

        sql = optimistic ? build_optimistic_update_sql : build_update_by_primary_key_sql

        types = []

        columns.each do |c|
          type = to_type_symbol(c)
          types << type
        end

        if optimistic

          columns.each do |c|
            type = to_type_symbol(c)
            types << type
            types << type if c.null
          end

        else

          keys = primary_key_columns

          keys.each do |c|
            type = to_type_symbol(c)
            types << type
          end

        end

        values = []

        keys = primary_key_columns

        group.each do |record|
          row = []

          columns.each do |c|
            v = record.read_attribute(c.name)
            row << v
          end

          if optimistic

            orginal = record.orginal_selected_record
            columns.each do |c|
              v = orginal[c.name]
              row << v
              row << v if c.null
            end

          else

            keys.each { |c| row << record[c.name] }

          end

          values << row
        end

        count = execute_batch_update(sql, types, values, optimistic)

        count
      end

      public

      def insert_on_missing_group(keys, group, _options = {})
        # fail 'the give key array is empty' if keys.empty?

        keys = Array(primary_key) if keys.nil? || keys.empty?

        sql = "
        merge into #{table_name} target
        using ( select #{columns.map { |c| ":#{columns.index(c) + 1} #{c.name}" }.join(', ')} from dual ) source
        on ( #{keys.map { |c| "target.#{c} = source.#{c}" }.join(' and ')}  )
        when not matched then
        insert ( #{columns.map(&:name).join(', ')} )
        values( #{columns.map { |c| "source.#{c.name}" }.join(', ')} )
        "

        types = columns.map { |c| to_type_symbol(c) }

        values = []

        group.each do |record|
          row = []

          columns.each do |c|
            v = record.read_attribute(c.name)
            row << v
          end

          values << row
        end

        begin
          result = execute_batch_update(sql, types, values, false)
        rescue StandardError => e
          raise ActiveRecord::StatementInvalid, "#{e.message}\n#{sql}"
        end

        group.each(&:unset_new_record)

        result
      end

      def delete_group(group, options = {})
        check_group(group)

        optimistic = options[:optimistic]
        optimistic = true if optimistic.nil?

        to_delete = group.reject(&:new_record?)

        if optimistic && !to_delete.reject(&:orginal_selected_record).empty?
          raise NoOrginalRecordFound
        end

        sql = optimistic ? build_optimistic_delete_sql : build_delete_by_primary_key_sql

        types = []

        if optimistic

          columns.each do |c|
            type = to_type_symbol(c)
            types << type
            types << type if c.null
          end

        else

          keys = primary_key_columns

          keys.each do |c|
            type = to_type_symbol(c)
            types << type
          end

        end

        values = []

        if optimistic

          to_delete.each do |record|
            row = []
            orginal = record.orginal_selected_record
            columns.each do |c|
              v = orginal[c.name]
              row << v
              row << v if c.null
            end

            values << row
          end

        else

          keys = primary_key_columns

          to_delete.each do |record|
            row = keys.map { |c| record[c.name] }
            values << row
          end

        end

        count = execute_batch_update(sql, types, values, optimistic)

        count
      rescue ExternalDataChange => e
        raise e
      rescue Exception => e
        raise StatementError, "#{sql} #{e.message}"
      end
    end
  end
end
