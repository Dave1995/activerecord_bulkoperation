module ActiveRecord
  class Base

    class << self

      # old style group find like PItem.find_group_by( :i_company => [45,45,45], :i_itemno => [1,2,3], :i_size => [0,0,0] )
      # leads to a sql statement in the form of 'SELECT * FROM table WHERE ((i_company, i_itemno, i_size) IN ((45, 1, 0), (45, 2, 0), (45, 3, 0)))'

      def find_group_by(args)
        fail 'no hash given, use Table.all() instead' if args.nil? || args.empty? || (not args.is_a?(Hash))
        fail 'args is not a hash of arrays' if args.select { |k,v| k.is_a?(Symbol) || v.is_a?(Array) }.size != args.size
        
        conditions = ( args.is_a?(Hash) && args[:conditions] ) || args  
        tuple_size = conditions.size
        array_size = 0
        conditions.each do |k,v|
          array_size = v.size unless array_size > 0
          fail 'not all arrays are of the same size' unless v.size == array_size
        end

        symbols = conditions.keys
        values = Array.new(array_size) { Array.new(tuple_size) }

        # to recurse is golden, to transpose ... divine!
        i = 0
        (array_size*tuple_size).times do
          values[i/tuple_size][i%tuple_size] = args.values[i%tuple_size][i/tuple_size]
          i += 1
        end

        return where_tuple(symbols, values)
      end

      # not really compatible to the rest of ActiveRecord but it works
      # provide parameters like this: symbols_tuple = [ :col1, :col2, :col3 ]
      # and values_tuples = [ [1, 4, 7], [2, 5, 8], [3, 6, 9]]
      def where_tuple(symbols_tuple, values_tuples)
        if symbols_tuple.nil? || symbols_tuple.size == 0 || (not symbols_tuple.is_a?(Array)) || (not symbols_tuple.select { |s| not s.is_a?(Symbol) }.empty?)
          fail 'no symbols given or not every entry is a symbol'
        end

        tuple_size = symbols_tuple.size
        #fail "don't use this method if you're not looking for tuples." if tuple_size < 2

        if values_tuples.nil? || values_tuples.size == 0 || (not values_tuples.is_a?(Array)) || (not values_tuples.select { |s| not s.is_a?(Array) }.empty?)
          fail 'no values given or not every value is an array'
        end

        tuple_part = "(#{(['?']*tuple_size).join(',')})"
        in_stmt = "(#{([tuple_part]*values_tuples.size).join(', ')})"
        stmt = "(#{symbols_tuple.map { |sym| sym.to_s }.join(', ')}) IN #{in_stmt}"

        res = where(stmt, *(values_tuples.flatten!))

        return res
      end

    end # end of class << self
  end # end of class Base
end
