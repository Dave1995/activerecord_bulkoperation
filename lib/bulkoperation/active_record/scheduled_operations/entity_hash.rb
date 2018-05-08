#  
#
# Author:: Andre Kullmann
#
class Bulkoperation::ActiveRecord::ScheduledOperations::EntityHash < Hash  
        
  def each_pair_in_detail_hierarchy(&block)
    visited = []

    each_pair do |k, v|

      next if visited.include?(k)

      in_detail_hierarchy(k, visited, &block)

    end
  end
  
  def each_pair_in_master_hierarchy(&block)
    visited = []

    each_pair do |k, v|

      next if visited.include?(k)

      in_master_hierarchy(k, visited, &block)

    end
  end

  private

  def in_detail_hierarchy(record_class, visited, &block)
    return if visited.include?(record_class)

    visited << record_class

    record_class.foreign_detail_tables.each do |table_name|

      if key = find_key_by_table_name(table_name)

        in_detail_hierarchy(key, visited, &block)
      end
    end

    list = self[ record_class] and yield record_class, list
  end

  def in_master_hierarchy(record_class, visited, &block)
    return if visited.include?(record_class)

    visited << record_class

    record_class.foreign_master_tables.each do |table_name|

      if key = find_key_by_table_name(table_name)

        in_master_hierarchy(key, visited, &block)
      end
    end

    list = self[ record_class] and yield record_class, list
  end

  def find_key_by_table_name(table_name)
    name = table_name.upcase
    result = keys.select { |k| k.table_name.upcase == name }
    fail '' if result.size > 1
    result.first
  end

end
 