require_relative 'test_helper'

class FlushDirtyObjectsTest < ActiveSupport::TestCase
  include Bulkoperation::ActiveRecord::ScheduledOperations

  def test_object_exists
    obj = FlushDirtyObjects.new
    assert_not_nil obj
  end

end

