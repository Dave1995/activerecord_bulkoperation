require 'active_record/associations'

module ActiveRecord

  module Persistence
    module ClassMethods

        alias_method :instantiate_without_save_original, :instantiate

        def instantiate(attributes, column_types)
          record = instantiate_without_save_original(attributes, column_types)
          record.save_original
          record
        end
    end
  end

  module Associations

    module ManyToManyTables
    end

    class CollectionProxy       
      
      def schedule_merge(record)        
        options = proxy_association.reflection.options
        macro = proxy_association.reflection.macro
        if(proxy_association.is_a?(ActiveRecord::Associations::HasManyThroughAssociation))
          handle_has_many_through_schedule_merge(record)
          return
        end  
        if(macro == :has_many)
          handle_has_many_schedule_merge(record)
          return
        end      
      end

      def handle_has_many_schedule_merge(record)
        pk = proxy_association.reflection.options[:primary_key] || proxy_association.owner.class.primary_key
        fk = proxy_association.reflection.options[:foreign_key] || "#{proxy_association.owner.class.to_s.underscore.downcase}_id"
        if(pk.is_a?(Array))
          puts "is a array"
          pk.each do |pk_item|
            pk_item_val = proxy_association.owner[pk_item.to_s]
            record.send("#{pk_item.to_s}=",pk_item_val)
          end
        else
          pk_val = proxy_association.owner[pk.to_s]        
          record.send("#{fk}=",pk_val) 
        end
        
        record.schedule_merge
        self << record
      end

      def parent_reflection
        proxy_association.reflection.parent_reflection[1]
      end

      def get_m_t_m_table_name
        parent_reflection.options[:join_table] || [proxy_association.owner.class.table_name,proxy_association.klass.table_name].sort.join('_')
      end

      def parent_pk
        parent_reflection.options[:primary_key] || proxy_association.owner.class.primary_key
      end

      def parent_association_pk
        parent_reflection.options[:association_primary_key] || "#{proxy_association.owner.class.to_s.underscore.downcase}_id"
      end

      def child_pk
        parent_reflection.options[:foreign_key] || proxy_association.klass.primary_key
      end

      def child_association_pk
        parent_reflection.options[:association_foreign_key] || "#{proxy_association.klass.to_s.underscore.downcase}_id"
      end
      
      #TODO remove
      alias_method :count_without_merges, :count
      def count
        count_without_merges + ( @internal_new_count.to_i)
      end
      
      def handle_has_many_through_schedule_merge(record)        
     # TODO AK doesn't work well 
        self << record 
        
=begin
        join_model = Class.new(ActiveRecord::Base) do
          class << self;           
            attr_accessor :table_info
          end
          def self.table_name
            table_info.table_name
          end
        end
        join_model.table_info = OpenStruct.new(:table_name => get_m_t_m_table_name)        
        unless(ManyToManyTables.const_defined?(get_m_t_m_table_name.camelize))
          ManyToManyTables.const_set get_m_t_m_table_name.camelize,join_model
        end
        #puts "RP DEBUG child_pk: #{child_pk} parent_pk: #{parent_pk}"
        #puts "RP DEBUG child_association_pk: #{child_association_pk} parent_association_pk: #{parent_association_pk}"
        #puts "RP DEBUG table_name: #{get_m_t_m_table_name}"
        c = ManyToManyTables.const_get get_m_t_m_table_name.camelize
        record.schedule_merge
        obj = c.new
        puts "AK: #{obj.class.name}"
        puts "AK: #{obj.class.name}.#{child_association_pk} = #{proxy_association.owner.class.name}.#{parent_pk} #{proxy_association.owner.send(parent_pk)}" 
        puts "AK: #{obj.class.name}.#{child_association_pk} = #{record.class.name}.#{parent_association_pk} #{record.send(parent_association_pk)}" 
        obj.send("#{parent_association_pk}=", proxy_association.owner.send(parent_pk))
        obj.send("#{child_association_pk}=" , record.send(parent_association_pk))
        obj.schedule_merge
        pp obj
        @internal_new_count ||= 0 
        @internal_new_count += 1
=end
      end

    end

    class JoinDependency # :nodoc:

        def instantiate_each(row, &block)
          if row
            primary_id = join_base.record_id(row)
            unless @base_records_hash[primary_id]
              if @base_records_in_order.size > 0
                yield @base_records_in_order.first
                # Die Theorie ist hier ein primary_key der Haupttabelle
                # ist verarbeitet und nun kann der Satz entsorgt werden.
                @base_records_in_order.pop
                # instatiate_each nicht das gesamte Ergebnis durchsucht,
                # wird @base_record_hash nur fuer den Gruppenwechsel
                # verwendet.
                # Bei einem neuen primary_key wird der Hash geleert.
                @base_records_hash = {}
                # record cache leeren
                # join_base.cached_record = {}
                @joins.each { |j| j.cached_record = {} }
              end
              #RP TODO check if instantiate call is correct with an empty hash or where to get the 2nd parameter
              @base_records_in_order << (@base_records_hash[primary_id] = join_base.instantiate(row,{}))
            end
            construct(@base_records_hash[primary_id], @associations, join_associations.dup, row)
          else
            yield @base_records_in_order.first
          end
        end

      class JoinBase 
        attr_accessor :cached_record
        def extract_record(row)
          # if the :select option is set, only the selected field should be extracted
          # column_names_with_alias.inject({}){|record, (cn, an)| record[cn] = row[an] if row.has_key?(an); record}
          record = {}
          column_names_with_alias.each { |(cn, an)| record[cn] = row[an] if row.key?(an) }
          record
        end
        alias_method :instantiate_without_save_original, :instantiate        
        def instantiate(row, aliases)          
          instantiate_without_save_original(row, aliases)
        end
      end
    end
  end
end

