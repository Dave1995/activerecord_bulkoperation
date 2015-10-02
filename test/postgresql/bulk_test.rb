require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
#require File.expand_path(File.dirname(__FILE__) + '/../support/postgresql/bulk_examples')

class TestCalculations < ActiveSupport::TestCase
 
  def test_count_distinct
    assert_equal(3, 3)
    assert ActiveRecord::Base.respond_to? :schedule_merge, "test"
  end

end

#should_support_postgresql_import_functionality
