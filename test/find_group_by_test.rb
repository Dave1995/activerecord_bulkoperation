
require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class FindGroupByTest < ActiveSupport::TestCase

  def teardown
    puts '- FindGroupByTest.teardown(): nununu'
    Item.delete_all
  end

  def setup
    puts '- FindGroupByTest.setup(): nu'
    Item.new( :itemno => 'A', :size => 1, :company => 21).save!
    Item.new( :itemno => 'B', :size => 2, :company => 22).save!
    Item.new( :itemno => 'C', :size => 3, :company => 23).save!
    Item.new( :itemno => 'D', :size => 4, :company => 24).save!
    Item.new( :itemno => 'E', :size => 5, :company => 25).save!
    Item.new( :itemno => 'F', :size => 6, :company => 26).save!
    Item.new( :itemno => 'G', :size => 7, :company => 27).save!
    Item.new( :itemno => 'H', :size => 8, :company => 28).save!
    Item.new( :itemno => 'I', :size => 9, :company => 29).save!
    Item.new( :itemno => 'J', :size => 10, :company => 30).save!
    Item.new( :itemno => 'K', :size => 11, :company => 31).save!
    Item.new( :itemno => 'L', :size => 12, :company => 32).save!
    Item.new( :itemno => 'M', :size => 13, :company => 33).save!
    Item.new( :itemno => 'N', :size => 14, :company => 34).save!
  end

  def test_items_exist
    puts '- FindGroupByTest.test_items_exist(): nunu'
    assert_equal( 14, Item.all.count)
    i1 = Item.find_by( itemno: 'A')
    assert_not_nil( i1 )
    assert_equal( 'A', i1.itemno)
    assert_equal( 1, i1.size)
    assert_equal( 21, i1.company)
    i2 = Item.find_by( itemno: 'B')
    assert_not_nil( i2 )
    assert_equal( 'B', i2.itemno)
    assert_equal( 2, i2.size)
    assert_equal( 22, i2.company)

    assert_equal( 23, Item.find_by( itemno: 'C').company)
    assert_equal( 24, Item.find_by( itemno: 'D').company)
    assert_equal( 25, Item.find_by( itemno: 'E').company)
    assert_equal( 26, Item.find_by( itemno: 'F').company)
    assert_equal( 27, Item.find_by( itemno: 'G').company)
    assert_equal( 28, Item.find_by( itemno: 'H').company)
    assert_equal( 29, Item.find_by( itemno: 'I').company)
    assert_equal( 30, Item.find_by( itemno: 'J').company)
    assert_equal( 31, Item.find_by( itemno: 'K').company)
    assert_equal( 32, Item.find_by( itemno: 'L').company)
    assert_equal( 33, Item.find_by( itemno: 'M').company)
    assert_equal( 34, Item.find_by( itemno: 'N').company)
  end

  def test_find_by_multiple_columns
    puts '- FindGroupByTest.test_find_by_multiple_columns(): nunu'

    i1 = Item.find_by( itemno: 'A')
    i2 = Item.find_by( itemno: 'B')
    i3 = Item.find_by( itemno: 'C')

    # this is how it was done before. With rails4 this is not necessary anymore
    #is = Item.find_group_by( :itemno => ['A', 'B', 'C'], :size => [1, 2, 3], :company => [21, 22, 23])
    # now ActiveRecord has an easy way to do this
    is = Item.where( { itemno: ['A', 'B', 'C'], size: [1, 2, 3], company: [21, 22, 23] } )

    assert_not_nil( is )
    assert_equal( 3, is.count)
    assert_equal( i1, is[0])
    assert_equal( i2, is[1])
    assert_equal( i3, is[2])

    is = Item.where( { itemno: ['A', 'B', 'C'], size: [1, 2, 4], company: [21, 22, 23] } )
    assert_not_nil( is )
    assert_equal( 2, is.count)
    assert_equal( i1, is[0])
    assert_equal( i2, is[1])

    is = Item.where( { itemno: ['A', 'B', 'C'], size: [1, 2, 3], company: [23, 23, 23] } )
    assert_not_nil( is )
    assert_equal( 1, is.count)
    assert_equal( i3, is[0])

    is = Item.where( { itemno: ['A', 'B', 'C'], size: [1, 2], company: [21] } )
    assert_equal( 1, is.count)
    assert_equal( i1, is[0])
  end
end
