module Bulkoperation
end

module Bulkoperation::ActiveRecord
end

module Bulkoperation::ActiveRecord::ConnectionListeners
end

require_relative 'connection_listeners/abstract_adapter'
require_relative 'connection_listeners/connection_object'
require_relative 'connection_listeners/transaction_object'