# A TransactionObject belongs to a connection. It's like a singleton for each transaction.
#
# Author:: Andre Kullmann
#
class Bulkoperation::ActiveRecord::ConnectionListeners::TransactionObject
       
  def self.get
    result = ActiveRecord::Base.connection.connection_listeners.find { |l| l.class == self }
    unless result
      result = new
      ActiveRecord::Base.connection.connection_listeners << result
    end
    result
  end

  def after_commit
    close
    ActiveRecord::Base.connection.connection_listeners.delete(self)
  end

  def after_rollback
    close
    ActiveRecord::Base.connection.connection_listeners.delete(self)
  end

  def after_rollback_to_savepoint
  end

  def close
  end

end