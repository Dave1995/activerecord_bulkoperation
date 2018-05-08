require_relative 'test_helper'

class EntityHashTest < ActiveSupport::TestCase
  include Bulkoperation::ActiveRecord::ScheduledOperations

  def test_object_exists
    obj = EntityHash.new
    assert_not_nil obj
  end

end

