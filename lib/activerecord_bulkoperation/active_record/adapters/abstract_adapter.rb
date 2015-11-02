require "activerecord_bulkoperation/adapters/abstract_adapter"

module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:
    class AbstractAdapter # :nodoc:
      include ActiveRecord::Bulkoperation::AbstractAdapter::InstanceMethods
    end

    class ConnectionPool

      alias_method :super_initialize, :initialize
      def initialize(spec)
        super_initialize(spec)
        @timeout = 5
      end

      def log
        ActiveRecord::Base.logger
      end

      def set_connection(connection)
        id   = ActiveRecord::Base.connection_pool.send :current_connection_id
        hash = ActiveRecord::Base.connection_pool.instance_variable_get('@reserved_connections')
        hash[id] = connection
      end

      def get_connection
        id   = ActiveRecord::Base.connection_pool.send :current_connection_id
        hash = ActiveRecord::Base.connection_pool.instance_variable_get('@reserved_connections')
        hash[id]
      end

      # after checkout clear the scheduled operation if necessary
      alias_method :super_checkout, :checkout
      def checkout
        @timeout = 5
        connection = super_checkout
        connection.clear_scheduled_operations if connection.respond_to?('clear_scheduled_operations')
        start_plsql_profiling(connection)
        connection
      end

      # before checkout clear the scheduled operation if necessary
      alias_method :super_checkin, :checkin
      def checkin(connection)
        connection.clear_scheduled_operations if connection.respond_to?('clear_scheduled_operations')
        connection.connection_listeners.each { |l| l.before_close if l.respond_to?('before_close') } if connection.respond_to?('connection_listeners')
        stop_plsql_profiling(connection)
        super_checkin(connection)
      end

      private

      # if we are running for pl/sql coverage
      # we need to start the profiler at checkout
      # and stop the profiler at checkin
      if ENV['SQL_COVERAGE_RUN'].present?

        def start_plsql_profiling(connection)
          run_comment = ENV['SQL_COVERAGE_RUN']
          sql = "begin dbms_profiler.start_profiler('#{run_comment}'); end;"
          connection.execute(sql)
        end

        def stop_plsql_profiling(connection)
          sql = 'begin dbms_profiler.stop_profiler(); dbms_profiler.flush_data(); end;'
          connection.execute(sql)
        end

      else

        def start_plsql_profiling(connection)
        end

        def stop_plsql_profiling(connection)
        end

      end
    end
  end
end
