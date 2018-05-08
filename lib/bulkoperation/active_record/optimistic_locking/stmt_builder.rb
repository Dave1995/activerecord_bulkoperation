module ActiveRecord
    
  class Base

    class << self

      def build_delete_by_primary_key_sql
        keys = primary_key_columns

        index = 1
        "DELETE FROM #{table_name} " \
        'WHERE ' +         "#{keys.map { |c| string = "#{c.name} = :#{index}"; index += 1; string }.join(' AND ') } "
      end

      def build_optimistic_delete_sql
        index = 1
        "DELETE FROM #{table_name} " \
        'WHERE ' +         "#{columns.map { |c| string = build_optimistic_where_element(index, c); index += 1; index += 1 if c.null; string }.join(' AND ') } " 
      end

      def build_optimistic_update_sql
        index = 1
        "UPDATE #{table_name} " \
        'SET ' +
        "#{columns.map { |c| string = c.name + " = :#{index}"; index += 1; string }.join(', ') } " +
        'WHERE ' +
        "#{columns.map { |c| string = build_optimistic_where_element(index, c); index += 1; index += 1 if c.null; string }.join(' AND ') } "# +
        #"AND ROWID = :#{index}"
      end

      def build_update_by_primary_key_sql
        keys = primary_key_columns

        index = 1
        "UPDATE #{table_name} " \
        'SET ' +
        "#{columns.map { |c| string = c.name + " = :#{index}"; index += 1; string }.join(', ') } " +
        'WHERE ' +
        "#{keys.map { |c| string = "#{c.name} = :#{index}"; index += 1; string }.join(' AND ') } "
      end

      private

      def primary_key_columns
        @primary_key_columns ||= primary_key_as_array.map { |c| columns_hash[c.to_s] }
      end

      def primary_key_as_array
        primary_key.is_a?(Array) ? primary_key : [primary_key]
      end

      def build_optimistic_where_element(index, column)
        sql = '( '        
        # AK: remove timezone information. ruby appends the summer/winter timezone releated to the date and send this as timestamp to oracle
        #    and a timestamp with timezone is not equals the date in the row
        if column.type == :datetime
          sql += "#{column.name} = cast( :#{index} as date ) "
        else
          sql += "#{column.name} = :#{index} "
        end

        index += 1
        if column.null
          sql += "OR ( #{column.name} IS NULL AND :#{index} IS NULL ) "
          index += 1
        end

        sql += ') '
      end

    end # class << self

  end # Base

end # ActiveRecord
