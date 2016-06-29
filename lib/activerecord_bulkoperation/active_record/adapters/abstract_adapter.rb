require "activerecord_bulkoperation/adapters/abstract_adapter"

module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:

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
        connection
      end

      # before checkout clear the scheduled operation if necessary
      alias_method :super_checkin, :checkin
      def checkin(connection)
        connection.clear_scheduled_operations if connection.respond_to?('clear_scheduled_operations')
        connection.connection_listeners.each { |l| l.before_close if l.respond_to?('before_close') } if connection.respond_to?('connection_listeners')
        super_checkin(connection)
      end

    end
  end
end
