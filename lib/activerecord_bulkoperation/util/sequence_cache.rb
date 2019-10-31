# Will fetch the next N values from a sequence and store it in a queue. 
# Now the values will can be fetched from the queue without any database roundtrip. 
# If the queue is empty, the next N values will be fetched from database and stored in the queue.
#
# It's using the DUAL table so it should only work with oracle.
# 
# Author:: Andre Kullmann
#
module ActiveRecord
  module Bulkoperation
    module Util
      class SequenceCache        

        #
        # seq - the sequence name to use with the SequenceCache object
        # refetch - how many values should be fetch from the database with each roundtrip 
        def initialize(seq, prefetch = 10)          
          @seq, @prefetch = seq, prefetch
          @queue = Queue.new
        end

        #
        # return - the next value from the sequence
        def next_value          
          while ( value = next_value_from_queue ).nil?
            fill_queue
          end
          value 
        end

        private

        def next_value_from_queue
	        @queue.pop(true) 
        rescue ThreadError
          nil
        end

        def fill_queue
          fetch.each do |f|
            @queue << f
          end
        end

        def fetch
          st = ActiveRecord::Base.connection.exec_query("SELECT #{@seq}.nextval id FROM dual connect by level <= :a", "SQL", [[nil,@prefetch]])
          st.map {|r| r['id']}
        end
      end
    end
  end
end
