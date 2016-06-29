require 'java'

module ActiveRecord
  module Bulkoperation
    module BatchUpdate
      module InstanceMethods

        def enhanced_write_lobs #:nodoc:
          # disable this feature for jruby
        end

        def execute_batch_update(sql, types, values, optimistic = true)
          fail ArgumentError.new('String expected') unless sql.is_a? String

          types = [types] unless types.is_a? Array
          fail ArgumentError.new('Array of symbols expected') unless types.select { |i| not i.is_a? Symbol }.empty?

          fail ArgumentError.new('Array expected') unless values.is_a? Array
          values = [values] unless values.select { |i| not i.is_a? Array }.empty?

          unless values.select { |i| not i.count == types.count }.empty?
            fail ArgumentError.new('types.count must be equal to arr.count for every arr in values')
          end

          unless connection.adapter_name == 'Oracle' || connection.adapter_name == 'OracleEnhanced'
            fail "Operation is provided only on Oracle connections. (adapter_name is #{connection.adapter_name})"
          end

          stmt = connection.raw_connection.prepareStatement(sql)

          count = 0

          begin
            stmt.setExecuteBatch(300) # TODO

            for row in values
              i = 1
              ( 0..row.count - 1).each{ |j|
                bind(stmt, i, types[j], row[j])
                i += 1
              }

              count += stmt.executeUpdate

            end

            count += stmt.sendBatch

            fail ExternalDataChange.new(sql) if count != values.count and optimistic

          rescue Exception => e
            exc = e
            while exc.kind_of?(Java.java.lang.Exception) and exc.cause
              exc = exc.cause
            end
            raise exc
          ensure
            stmt.close
          end

          count
        end

        private
        def bind(stmt, index, type, value)
          if type == :string
            stmt.setString(index, value) if value
            stmt.setNull(index, Java.java.sql.Types::VARCHAR) unless value

          elsif type == :integer
            stmt.setLong(index, value) if value
            stmt.setNull(index, Java.java.sql.Types::NUMERIC) unless value

          elsif type == :float
            stmt.setDouble(index, value) if value
            stmt.setNull(index, Java.java.sql.Types::NUMERIC) unless value

          elsif type == :date

            if value
              # TODO Timezone handling; if the given value have another timezone as default
              c = Java.java.util.Calendar.getInstance
              c.set(Java.java.util.Calendar::YEAR, value.year)
              c.set(Java.java.util.Calendar::MONTH, value.month - 1)
              c.set(Java.java.util.Calendar::DATE, value.day)
              if value.kind_of?(DateTime) or value.kind_of?(Time)
                c.set(Java.java.util.Calendar::HOUR_OF_DAY,   value.hour)
                c.set(Java.java.util.Calendar::MINUTE, value.min)
                c.set(Java.java.util.Calendar::SECOND, value.sec)
              else
                c.set(Java.java.util.Calendar::HOUR_OF_DAY,   0)
                c.set(Java.java.util.Calendar::MINUTE, 0)
                c.set(Java.java.util.Calendar::SECOND, 0)
              end
              c.set(Java.java.util.Calendar::MILLISECOND, 0)

              stmt.setTimestamp(index, Java.java.sql.Timestamp.new(c.getTimeInMillis))

            else
              stmt.setNull(index, Java.java.sql.Types::TIMESTAMP)
            end

          else

            fail ArgumentError.new("unsupported type #{type}")
          end
        end
      end
    end
  end
end
