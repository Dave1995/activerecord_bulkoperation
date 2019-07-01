module ActiveRecord
  module Bulkoperation
    module BatchUpdate
      module InstanceMethods

        def execute_batch_update(sql, types, values, optimistic = true)
          fail ArgumentError.new('String expected') unless sql.is_a? String

          types = [types] unless types.is_a? Array
          fail ArgumentError.new('Array of Symbol expected') unless types.select { |i| not i.is_a? Symbol }.empty?

          fail ArgumentError.new('Array expected') unless values.is_a? Array
          values = [values] unless values.select { |i| not i.is_a? Array }.empty?

          return 0 if values.empty?

          unless values.select { |i| not i.count == types.count }.empty?
            fail ArgumentError.new('types.count must be equal to arr.count for every arr in values')
          end

          unless connection.adapter_name == 'Oracle' || connection.adapter_name == 'OracleEnhanced'
            fail "Operation is provided only on Oracle connections. (adapter_name is #{connection.adapter_name})"
          end

          oci_conn = connection.raw_connection if connected?
          fail 'Unable to access the raw OCI connection.' unless oci_conn
          cursor = oci_conn.parse(sql)
          fail "Unable to obtain cursor for this statement:\n#{sql}." unless cursor

          if check_date_homogeneously(types, values)
            affected_rows = execute_batch_update_array(cursor, sql, types, values, optimistic)
          else
            affected_rows = execute_batch_update_single(cursor, sql, types, values, optimistic)
          end

          affected_rows
        end

        private

        # checks if all date values in one column of a row are of the same date type (Date/DateTime)
        def check_date_homogeneously(types, rows)
          types.each_with_index do |type, i|
            if type == :date
              common_type = nil
              rows.each do |row|
                type = get_date_type(row[i])

                if common_type.nil?
                  common_type = type
                elsif common_type != type
                  return false
                end

              end
            end
          end
          return true
        end

        # execute batch update by single statement execution.
        # slower than array statement execution, only used when date values in a column have inhomogeneous date types
        def execute_batch_update_single(cursor, sql, types, values, optimistic)
          affected_rows = 0

          begin
            values.each do |row|

              (0..row.count - 1).each do |i|
                bind(cursor, i + 1, types[i], row[i])
              end

              result = cursor.exec
              #result = 1
              if result != 1 and optimistic

                msg = sql
                i = 1
                row.each do |v|
                  val = get_value(v)
                  msg = msg.gsub(":#{i},", connection.quote(val) + ',')
                  msg = msg.gsub(":#{i} ", connection.quote(val) + ' ')
                  i += 1
                end
                i -= 1
                msg = msg.gsub(":#{i}", connection.quote(get_value(row.last)))

                fail ExternalDataChange.new("The record you want to update was updated by another process.\n#{msg}")
              end

              affected_rows += result

              connection.send(:log, sql, 'Update') {}
            end
          ensure
            cursor.close
          end

          affected_rows
        end

        # execute batch update by array statement execution.
        # faster than single statement execution, can only be used when all date values
        # in a column have homogeneous date types
        def execute_batch_update_array(cursor, sql, types, values, optimistic)
          affected_rows = 0

          begin
            values_columnwise = convert_rows_to_columns(values, types.size)

            cursor.max_array_size = values.size

            (0..types.size - 1).each do |i|
              bind_column(cursor, i + 1, types[i], values_columnwise[i])
            end

            result = cursor.exec_array

            result_is_int = result.is_a? Integer

            fail ExternalDataChange.new(sql) if result_is_int and result != values.count and optimistic

            affected_rows += result_is_int ? result : cursor.row_count

            connection.send(:log, sql, 'Update') {}
          ensure
            cursor.close
          end

          affected_rows
        end

        def convert_rows_to_columns(values_rowise, count)
          values_columnwise = []
          (0..count-1).each do |i|
            column = []
            values_rowise.each do |row|
              column << get_value(row[i])
            end
            values_columnwise << column
          end
          values_columnwise
        end

        def get_value(value)
          if(value.respond_to? :value)
            value.value
          else
            value
          end
        end

        def bind(cursor, index, type, input_value)
          value = get_value(input_value)
          if type == :string
            cursor.bind_param(":#{index}", value, String)

          elsif type == :integer
            cursor.bind_param(":#{index}", value, Fixnum)

          elsif type == :float
            cursor.bind_param(":#{index}", value, Float)

          elsif type == :date
            cursor.bind_param(":#{index}", value, get_date_type(value))

          else

            fail ArgumentError.new("unsupported type #{type}")
          end
        end

        def bind_column(cursor, index, type, column)
          if type == :string
            cursor.bind_param_array(":#{index}", column, String, get_max_string_length(column))

          elsif type == :integer
            cursor.bind_param_array(":#{index}", column, Fixnum)

          elsif type == :float
            cursor.bind_param_array(":#{index}", column, Float)

          elsif type == :date
            cursor.bind_param_array(":#{index}", column, get_date_type(column[0]))

          else

            fail ArgumentError.new("unsupported type #{type}")
          end
        end

        def get_max_string_length(column)
          return nil if column.nil?

          max_length = 0

          column.each do |value|
            next if value.nil?
            max_length = value.length if value.length > max_length
          end

          return max_length > 0 ? max_length : nil
        end

        def get_date_type(value)
          return Date if value.nil?

          if ( value.kind_of?(DateTime) or value.kind_of?(Time)) and value.hour == 0 and value.min == 0 and value.sec == 0
            return Date
          else
            return DateTime
          end
        end

      end
    end
  end
end