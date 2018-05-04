# A ConnectionObject belongs to a connection. It's like a singleton for each connection.
#
# Author:: Andre Kullmann
#
class Bulkoperation::ActiveRecord::ConnectionListeners::ConnectionObject
  def self.get
    result = ActiveRecord::Base.connection.connection_listeners.find { |l| l.class == self }
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
