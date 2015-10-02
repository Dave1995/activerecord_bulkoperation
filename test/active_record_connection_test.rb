require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class ActiveRecordConnectionTest < ActiveSupport::TestCase
  def test_count_distinct
    assert ActiveRecord::Base.connection.respond_to? :connection_listeners 
    assert ActiveRecord::Base.connection.respond_to? :commit_db_transaction
    assert ActiveRecord::Base.connection.respond_to? :rollback_db_transaction
    assert ActiveRecord::Base.connection.respond_to? :rollback_to_savepoint
    assert ActiveRecord::Base.connection.respond_to? :create_savepoint
  end
end