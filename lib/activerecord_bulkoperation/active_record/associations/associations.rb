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
              @base_records_in_order << (@base_records_hash[primary_id] = join_base.instantiate(row))
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

