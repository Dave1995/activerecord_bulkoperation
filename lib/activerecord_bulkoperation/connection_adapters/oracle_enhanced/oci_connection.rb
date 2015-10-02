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

          fail ArgumentError.new('types array must have same length as the arrays in values') unless values.select { |i| not i.count == types.count }.empty?

          fail 'Operation is provided only on Oracle connections.' unless connection.adapter_name == 'Oracle' || connection.adapter_name == 'OracleEnhanced'

          oci_conn = connection.raw_connection if connected?
          fail 'Unable to access the raw OCI connection.' unless oci_conn          
          cursor = oci_conn.parse(sql)
          fail "Unable to obtain cursor for this statement:\n#{sql}." unless cursor

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

        private

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
            if value.nil?
              cursor.bind_param(":#{index}", nil, Date)
            else              
              if  ( value.kind_of?(DateTime) or value.kind_of?(Time)) and value.hour == 0 and value.min == 0 and value.sec == 0
                cursor.bind_param(":#{index}", value, Date)
              else
                cursor.bind_param(":#{index}", value, DateTime)
              end
            end

          else

            fail ArgumentError.new("unsupported type #{type}")
          end
        end
      end
    end
  end  
end