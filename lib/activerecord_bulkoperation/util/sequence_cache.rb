module ActiveRecord
  module Bulkoperation
    module Util
      class SequenceCache        

        def initialize(seq, prefetch = 10)          
          @seq, @prefetch = seq, prefetch
          @queue = Queue.new
        end

        def next_value          
          if(@queue.blank?)
            fill_queue            
          end
          @queue.pop
        end

        private

        def fill_queue
          fetch.each do |f|
            @queue << f
          end
        end

        def fetch
          st = ActiveRecord::Base.connection.exec_query("SELECT #{@seq}.nextval id FROM dual connect by level <= 10")
          st.map {|r| r['id']}
        end
      end
    end
  end
end
