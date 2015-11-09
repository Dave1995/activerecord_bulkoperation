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

    class CollectionProxy
      def schedule_merge(record)        
        options = proxy_association.reflection.options
        macro = proxy_association.reflection.macro                
        if(macro == :has_many && options.empty?)
          handle_has_many_schedule_merge(record)
          return
        end
        if(proxy_association.is_a?(ActiveRecord::Associations::HasManyThroughAssociation))
          handle_has_many_through_schedule_merge(record)
          return
        end        
      end

      def handle_has_many_schedule_merge(record)
        fk = proxy_association.reflection.foreign_key
        pk = proxy_association.reflection.active_record_primary_key
        pk_val = proxy_association.owner.send(pk)
        record.send("#{fk}=",pk_val)        
        record.schedule_merge
      end

      def handle_has_many_through_schedule_merge(record)
        res = get_class_and_def(record)
        obj = res[:join_obj]
        record.schedule_merge
        this_pk = record.send(res[:this_id])
        remote_pk = proxy_association.owner.send(res[:parent_id])
        obj.send("#{res[:this_join_id]}=",this_pk)
        obj.send("#{res[:parent_join_id]}=",this_pk)
        obj.schedule_merge
      end

      def get_class_and_def(record)
        val = proxy_association.reflection.name.to_s.camelize
        this_to_join_class = proxy_association.owner.class.const_get("HABTM_#{val}")
        parent_to_join_class = proxy_association.klass.const_get("HABTM_#{proxy_association.owner.class.to_s.pluralize}")
        parent_id = proxy_association.owner.class.primary_key
        parent_join_id = parent_to_join_class.right_reflection.foreign_key
        this_join_id = this_to_join_class.right_reflection.foreign_key
        this_id = proxy_association.klass.primary_key
        {:parent_id => parent_id,:parent_join_id => parent_join_id,:this_join_id => this_join_id,:this_id => this_id,:join_obj => this_to_join_class.new}
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

