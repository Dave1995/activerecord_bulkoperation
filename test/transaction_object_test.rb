require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class TransactionObjectTest < ActiveSupport::TestCase

  def test_object_exists
    obj = ActiveRecord::Bulkoperation::Util::TransactionObject.new
    assert_not_nil obj
  end

end

