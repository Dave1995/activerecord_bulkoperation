class ActiveRecord::Base

    private
    def self.has_id_column?
        @has_id_column ||= columns_hash.key?('id')
      end

      private
      def self.sequence_exists?(name)
        arr = connection.find_by_sequence_name_sql_array(name)
        sql = sanitize_sql(arr)
        find_by_sql(sql).count == 1
      end

      private
      def self.check_sequence
        if sequence_exists?("#{table_name}_seq")
          "#{table_name}_seq"
        else
          sequence_name
        end
      end

      public
      def self.next_sequence_value
        @sequence_cache ||= Bulkoperation::ActiveRecord::Sequences::Cache.new(check_sequence)
        @sequence_cache.next_value
      end
    alias_method :schedule_merge_without_id_value_from_sequence, :schedule_merge
    public
    def schedule_merge
        set_id_from_sequence
        schedule_merge_without_id_value_from_sequence
      end
  
    # if id column is nil a value will be fetched from the sequence and set to the id property 
private
    def set_id_from_sequence
        if self.class.has_id_column? && @attributes.fetch_value( 'id' ).nil?
            new_id = self.class.next_sequence_value
            if self.class.primary_key == 'id'
            self.id = new_id
            else
            id_will_change!                                 # <- neu
        @attributes.write_from_user( 'id', new_id )
            end
        end
        end
      
end