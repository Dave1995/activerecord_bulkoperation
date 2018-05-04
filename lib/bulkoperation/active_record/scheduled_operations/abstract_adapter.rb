require "activerecord_bulkoperation/adapters/abstract_adapter"

module ActiveRecord # :nodoc:
  module ConnectionAdapters # :nodoc:

    class ConnectionPool

      # after checkout clear the scheduled operation if necessary
      alias_method :super_checkout, :checkout
      def checkout
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
