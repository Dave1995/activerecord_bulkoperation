module ActiveRecord
  module Bulkoperation
    module Util
      class FlushDirtyObjects < Util::TransactionObject
        class DirtyObjects
          attr_reader :insert_or_update
          attr_reader :insert_on_missing

          def initialize
            @insert_or_update  = Set.new
            @insert_on_missing = {}
          end
        end

        def initialize
          @scheduled_merges    = ActiveRecord::Bulkoperation::Util::EntityHash.new
          @scheduled_deletions = ActiveRecord::Bulkoperation::Util::EntityHash.new
        end

        def before_commit
          flush
        end

        def before_create_savepoint
          flush
        end

        def after_rollback_to_savepoint
          close
        end

        def close

          @scheduled_merges.values.each do |objects|
            if objects
              objects.insert_or_update.each { |record| record.on_closed_scheduled_operation }
              objects.insert_on_missing.values.each { |array| array.each{ |record| record.on_closed_scheduled_operation } }
            end
          end
          @scheduled_merges.clear

          @scheduled_deletions.values.each { |array| array and array.each { |record| record.on_closed_scheduled_operation } }
          @scheduled_deletions.clear
        end

        def add_insert_on_missing(keys,object)
          fail 'nil object' unless object
          ( ( @scheduled_merges[ object.class] ||= DirtyObjects.new).insert_on_missing[keys] ||= Set.new ) << object
        end

        def add_merge(object)
          fail 'nil object' unless object
          ( @scheduled_merges[ object.class] ||= DirtyObjects.new).insert_or_update << object
        end

        def add_delete(object)
          fail 'nil object' unless object
          ( @scheduled_deletions[ object.class] ||= []) << object
        end

        def flush(args = {})
          fail 'nil object' unless args

          affected = 0

          @scheduled_deletions.each_pair_in_detail_hierarchy do |k, v|
            affected += k.delete_group(v, args)
            @scheduled_deletions[k] = nil
            v.each { |record| record.on_closed_scheduled_operation }
          end

          @scheduled_merges.each_pair_in_master_hierarchy do |k, v|

            affected += k.merge_group( v.insert_or_update, args )

            v.insert_on_missing.each_pair do |keys,records|

              affected += k.insert_on_missing_group( keys, records, args )
            end

            @scheduled_merges[k] = nil
            v.insert_or_update.each  { |record| record.on_closed_scheduled_operation }
            v.insert_on_missing.values.each { |array| array.each{ |record| record.on_closed_scheduled_operation } }
          end

          affected
        end

        def flush_record_class(record_class, args = {})
          fail 'nil object' unless record_class
          fail 'nil object' unless args

          if list = @scheduled_deletions[ record_class]
            record_class.delete_group(list, args)
            @scheduled_deletions[ record_class] = nil
            list.each { |record| record.on_closed_scheduled_operation }
          end

          if objects = @scheduled_merges[ record_class]

            record_class.merge_group( objects.insert_or_update, args )

            objects.insert_on_missing.each_pair do |keys,records|

              record_class.insert_on_missing_group( keys, records, args )
            end

            @scheduled_merges[record_class] = nil
            objects.insert_or_update.each  { |record| record.on_closed_scheduled_operation }
            objects.insert_on_missing.values.each { |array| array.each{ |record| record.on_closed_scheduled_operation } }
          end
        end

      end
    end
  end
end
