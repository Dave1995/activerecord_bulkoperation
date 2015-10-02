require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class FlushDirtyObjectsTest < ActiveSupport::TestCase

  def test_object_exists
    obj = ActiveRecord::Bulkoperation::Util::FlushDirtyObjects.new
    assert_not_nil obj
  end

end

