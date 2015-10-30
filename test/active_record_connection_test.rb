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

  class MyTestClass
    def before_commit
      puts "get calllsslsl"
    end

    def after_rollback
      puts "get calllsslsl"
    end
  end

  def test_method_calls_definition    
    test_class = MyTestClass.new
    test_class.expects(:before_commit)
    test_class.expects(:after_commit)

    test_class.expects(:after_rollback)

    ActiveRecord::Base.connection.connection_listeners << test_class
    
    ActiveRecord::Base.connection.rollback_db_transaction

    ActiveRecord::Base.connection.commit_db_transaction
  end
end