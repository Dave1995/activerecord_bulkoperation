module ActiveRecord
  module Bulkoperation
    module Util
      class SequenceCache        

        def initialize(seq, prefetch = 10)          
          @seq, @prefetch = seq, prefetch
          @queue = Queue.new
        end

        def next_value          
          while ( value = next_value_from_queue ).nil?
            fill_queue
          end
          value 
        end

        private

        def next_value_from_queue
	  @queue.pop(true) 
        rescue ThreadError => e
          nil
        end

        def fill_queue
          fetch.each do |f|
            @queue << f
          end
        end

        def fetch
          st = ActiveRecord::Base.connection.exec_query("SELECT #{@seq}.nextval id FROM dual connect by level <= #{@prefetch}")
          st.map {|r| r['id']}
        end
      end
    end
  end
end
