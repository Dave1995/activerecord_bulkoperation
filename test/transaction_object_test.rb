require_relative 'test_helper'

class TransactionObjectTest < ActiveSupport::TestCase
  include Bulkoperation::ActiveRecord::ConnectionListeners

  def test_object_exists
    obj = TransactionObject.new
    assert_not_nil obj
  end

end

