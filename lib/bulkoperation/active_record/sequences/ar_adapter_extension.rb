class ActiveRecord::ConnectionAdapters::AbstractAdapter


    def find_by_sequence_name_sql_array(name)
        sql = 'select * from user_sequences where sequence_name = ?'
        [sql, name.upcase]
      end

end    