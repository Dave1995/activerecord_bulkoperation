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
        #@log ||= AmosBase::Util::Logging::Log.get('sql')
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
        logentry_login(connection)
        start_plsql_profiling(connection)
        connection
      end

      # before checkout clear the scheduled operation if necessary
      alias_method :super_checkin, :checkin
      def checkin(connection)
        puts "checkin"
        return unless connection
        connection.clear_scheduled_operations if connection.respond_to?('clear_scheduled_operations')
        connection.connection_listeners.each { |l| l.before_close if l.respond_to?('before_close') } if connection.respond_to?('connection_listeners')
        logentry_logout(connection)
        stop_plsql_profiling(connection)
        super_checkin(connection)
      end

      private

      def logentry_login(connection)
        if connection.class.name.index('Oracle')
          execution_id = AmosBase::Util::Context.get.execution_id || ENV['EXECUTION_ID']
          batch_name   = AmosBase::Util::Context.get.batch_name || ENV['EXECUTION_SCRIPT']
          opcode       = ENV['OPCODE']
          if execution_id.present? or batch_name.present? or opcode.present?
            if RuntimeEnv.smile?
              execution_part = execution_id.present? ? "/*:i #{execution_id}*/ #{execution_id} /*:e*/" : '/*:i */ null /*:e*/'
              batch_part     = batch_name.present? ? "/*:s '#{batch_name}'*/ '#{batch_name}' /*:e*/" : '/*:s */ null /*:e*/'
              opcode_part    = opcode.present? ? "/*:s '#{opcode}'*/ '#{opcode}' /*:e*/" : '/*:s */ null /*:e*/'
            else
              execution_part = execution_id.present? ? "#{execution_id}" : 'null'
              batch_part     = batch_name.present? ? "'#{batch_name}'" : 'null'
              opcode_part    = opcode.present? ? "'#{opcode}'" : 'null'
            end
            sql = "BEGIN LOGENTRY.LOGIN( #{batch_part}, #{execution_part}, #{opcode_part} ); END;"
            connection.execute(sql)
          end
        end
      rescue ActiveRecord::StatementInvalid => e
        log.debug(e.message)
        # do nothing maybe package doesn't exists ?
      rescue ArgumentError => e
        log.debug(e.message)
        # do nothing maybe package doesn't exists ?
      rescue Exception => e
        log.error(e)
      end

      def logentry_logout(connection)
        if connection.class.name.index('Oracle')
          sql = 'BEGIN LOGENTRY.LOGOUT(); END;'
          connection.execute(sql)
        end

      rescue ActiveRecord::StatementInvalid => e
        log.debug(e.message)
        # do nothing maybe package doesn't exists ?
      rescue ArgumentError => e
        log.debug(e.message)
        # do nothing maybe package doesn't exists ?
      rescue Exception => e
        log.error(e)
      end

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