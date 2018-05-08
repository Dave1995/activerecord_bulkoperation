# Make sure connections from the pool have attached scheduled dml operations.
#
# Author:: Andre Kullmann
#
class ActiveRecord::ConnectionAdapters::ConnectionPool

  # after checkout clear the scheduled operation if necessary
  alias_method :checkout_without_clear_scheduled_operations, :checkout
  def checkout
    connection = checkout_without_clear_scheduled_operations
    connection.clear_scheduled_operations if connection.respond_to?('clear_scheduled_operations')
    connection
  end

  # before checkout clear the scheduled operation if necessary
  alias_method :checkin_without_clear_scheduled_operations, :checkin
  def checkin(connection)
    connection.clear_scheduled_operations if connection.respond_to?('clear_scheduled_operations')
    connection.connection_listeners.each { |l| l.before_close if l.respond_to?('before_close') } if connection.respond_to?('connection_listeners')
    checkin_without_clear_scheduled_operations(connection)
  end

end
