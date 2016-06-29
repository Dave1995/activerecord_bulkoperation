# A ConnectionObject belongs to a connection. It's like a singleton for each connection.
#
# Author:: Andre Kullmann
#
class ConnectionObject
  def self.get
    result = ActiveRecord::Base.connection.connection_listeners.select { |l| l.class == self }.first
    unless result
      result = new
      ActiveRecord::Base.connection.connection_listeners << result
    end
    result
  end

  def before_close
    close
    ActiveRecord::Base.connection.connection_listeners.delete(self)
  end

  def close
  end
end
