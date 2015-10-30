require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class ActiveRecordConnectionTest < ActiveSupport::TestCase
  def test_method_definition
    assert ActiveRecord::Base.connection.respond_to? :connection_listeners 
    assert ActiveRecord::Base.connection.respond_to? :commit_db_transaction
    assert ActiveRecord::Base.connection.respond_to? :rollback_db_transaction
    assert ActiveRecord::Base.connection.respond_to? :rollback_to_savepoint
    assert ActiveRecord::Base.connection.respond_to? :create_savepoint
  
    assert ActiveRecord::Base.connection.respond_to? :commit_db_transaction_without_callback
    assert ActiveRecord::Base.connection.respond_to? :rollback_db_transaction_without_callback
    assert ActiveRecord::Base.connection.respond_to? :rollback_to_savepoint_without_callback
    assert ActiveRecord::Base.connection.respond_to? :create_savepoint_without_callback
  end

  def test_method_definition
    ActiveRecord::Base.connection.commit_db_transaction_without_callback
  end
end