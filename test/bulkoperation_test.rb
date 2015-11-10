require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class BulkoperationTest < ActiveSupport::TestCase

  def teardown
    TestTable.delete_all
  end

  def test_bulk_operation_methods    
    assert ActiveRecord::Base.respond_to? :flush_scheduled_operations
    test_obj = TestTable.new
    assert test_obj.respond_to? :schedule_merge
  end

  def test_bulk_operation_workflow
    test_obj = TestTable.new
    test_obj.author_name = 'test-workflow'
    test_obj.schedule_merge

    TestTable.flush_scheduled_operations
    record = TestTable.first
    assert_equal('test-workflow',record.author_name)    
  end

  def test_multi_thread
    thread_count = 5
    inner_count = 10
    threads = []
    thread_count.times do |t|
      t = Thread.new do
        inner_count.times do |i|
          test_obj = TestTable.new
          test_obj.author_name = "t1-#{1}"
          test_obj.schedule_merge  
        end
        TestTable.flush_scheduled_operations
      end
      threads << t
    end
    threads.each do |t|
      t.join
    end
    
    assert_equal (thread_count * inner_count) , TestTable.all.count      
  end

  def test_multi_update
    thread_count = 5
    inner_count = 10
    threads = []
    thread_count.times do |t|
      t = Thread.new do
        inner_count.times do |i|
          test_obj = TestTable.new
          test_obj.author_name = "t1-#{1}"
          test_obj.schedule_merge  
        end
        TestTable.flush_scheduled_operations
      end
      threads << t
    end
    threads.each do |t|
      t.join
    end
    
    assert_equal (thread_count * inner_count) , TestTable.all.count
    TestTable.all.each do |t|
      t.author_name = "tr-fff"
      t.schedule_merge
    end
    TestTable.flush_scheduled_operations      
  end

  def test_update_fk_relation
    #some problems during database creation and recreation
    return
    group = Group.new
    group.schedule_merge    
    test_obj = TestTable.new
    test_obj.author_name = 'test-1'
    test_obj.group_id = group.id
    test_obj.schedule_merge  

    ActiveRecord::Bulkoperation::Util::FlushDirtyObjects.get.flush
    
    TestTable.flush_scheduled_operations

    
    first = TestTable.first
    assert_equal('test-1',test_obj.author_name)
    
    first.author_name = 'test-2'
    first.schedule_merge    
    TestTable.flush_scheduled_operations

    assert_equal('test-2',first.author_name)    
  end

  def test_connection_listener_get_called 
    test_obj = TestTable.new
    test_obj.author_name = 'test-1'    
    test_obj.schedule_merge  

    assert_equal(0,TestTable.count)
    ActiveRecord::Base.connection.commit_db_transaction
    assert_equal(1,TestTable.count)
    first = TestTable.first
    assert_equal('test-1',test_obj.author_name)
    TestTable.delete_all    
  end

  def test_schedule_merge_relation
    group = Group.new
    group.schedule_merge    
    test_obj = TestTable.new
    test_obj.author_name = 'test-1'
    group.test_tables.schedule_merge(test_obj)
    
    ActiveRecord::Bulkoperation::Util::FlushDirtyObjects.get.flush  
  end

  def test_schedule_merge_has_and_belongs_to_many_relation
    part = Part.new
    part.schedule_merge
    assembly = Assembly.new
    part.assemblies.schedule_merge(assembly)
    ActiveRecord::Bulkoperation::Util::FlushDirtyObjects.get.flush
    db_part = Part.first    
    db_assembly = Assembly.first

    assert_equal(1,db_part.assemblies.count)
    assert_equal(db_assembly[:id],db_part.assemblies.first[:id])
  
    assert_equal(1,db_assembly.parts.count)
    assert_equal(db_part[:id],db_assembly.parts.first[:id])    
  end

  def test_schedule_merge_has_and_belongs_to_many_relation_custom_table_and_columns
    
    course = Course.new
    course.course_id = 10
    course.schedule_merge
    student = Student.new
    student.student_id = 12
    course.students.schedule_merge(student)
    ActiveRecord::Bulkoperation::Util::FlushDirtyObjects.get.flush
    return 
    db_part = Course.first    
    db_assembly = Assembly.first

    assert_equal(1,db_part.assemblies.count)
    assert_equal(db_assembly[:id],db_part.assemblies.first[:id])
  
    assert_equal(1,db_assembly.parts.count)
    assert_equal(db_part[:id],db_assembly.parts.first[:id])    
  end

  def test_schedule_merge_has_and_belongs_to_many_relation_self_join    
    product = Product.new
    product2 = Product.new
    product.schedule_merge
    product.related_products.schedule_merge(product2)
    ActiveRecord::Bulkoperation::Util::FlushDirtyObjects.get.flush
    return 
    db_part = Course.first    
    db_assembly = Assembly.first

    assert_equal(1,db_part.assemblies.count)
    assert_equal(db_assembly[:id],db_part.assemblies.first[:id])
  
    assert_equal(1,db_assembly.parts.count)
    assert_equal(db_part[:id],db_assembly.parts.first[:id])    
  end

end

