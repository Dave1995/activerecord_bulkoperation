require_relative 'abstract_adapter'
require_relative 'connection_object'
require_relative 'transaction_object'

ActiveRecord::ConnectionAdapters::AbstractAdapter.include( Bulkoperation::ActiveRecord::AbstractAdapter )