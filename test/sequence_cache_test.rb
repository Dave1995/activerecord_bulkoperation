require_relative 'test_helper'

class SequenceCacheTest < ActiveSupport::TestCase
  include Bulkoperation::ActiveRecord

  def test_object_exists
    obj = Sequences::Cache.new('groups_seq')
    assert_not_nil obj
  end

  def test_seq_cache_multi_thread
    cache = Sequences::Cache.new('groups_seq')
    res1 = []
    res2 = []
    t = Thread.new do
      1000.times do |i|
        res1 << cache.next_value        
      end
    end
    t2 = Thread.new do
      1000.times do |i|
        res2 << cache.next_value        
      end
    end
    t.join
    t2.join

    assert_equal 2000 , (res1 + res2).count
  end

end

