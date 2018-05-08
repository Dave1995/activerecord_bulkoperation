
require_relative 'test_helper'

class FindGroupByTest < ActiveSupport::TestCase

  def teardown
    Item.delete_all
  end

  def setup
    Item.new( :itemno => 'A', :sizen => 1, :company => 21).save!
    Item.new( :itemno => 'B', :sizen => 2, :company => 22).save!
    Item.new( :itemno => 'C', :sizen => 3, :company => 23).save!
    Item.new( :itemno => 'D', :sizen => 4, :company => 24).save!
    Item.new( :itemno => 'E', :sizen => 5, :company => 25).save!
    Item.new( :itemno => 'F', :sizen => 6, :company => 26).save!
    Item.new( :itemno => 'G', :sizen => 7, :company => 27).save!
    Item.new( :itemno => 'H', :sizen => 8, :company => 28).save!
    Item.new( :itemno => 'I', :sizen => 9, :company => 29).save!
    Item.new( :itemno => 'J', :sizen => 10, :company => 30).save!
    Item.new( :itemno => 'K', :sizen => 11, :company => 31).save!
    Item.new( :itemno => 'L', :sizen => 12, :company => 32).save!
    Item.new( :itemno => 'M', :sizen => 13, :company => 33).save!
    Item.new( :itemno => 'N', :sizen => 14, :company => 34).save!
  end

  def test_items_exist
    assert_equal( 14, Item.all.count)
    i1 = Item.find_by( itemno: 'A')
    assert_not_nil( i1 )
    assert_equal( 'A', i1.itemno)
    assert_equal( 1, i1.sizen)
    assert_equal( 21, i1.company)
    i2 = Item.find_by( itemno: 'B')
    assert_not_nil( i2 )
    assert_equal( 'B', i2.itemno)
    assert_equal( 2, i2.sizen)
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

  def test_find_group_by_params_test
    column_set = [ :itemno, :sizen, :company ]
    assert_raises( ArgumentError ) { Item.where_tuple(nil, nil) }
    assert_raises( ArgumentError ) { Item.where_tuple(column_set, nil) }
    assert_raises( ArgumentError ) { Item.where_tuple([], nil) }
    assert_raises( ArgumentError ) { Item.where_tuple(['string', 'strang'], nil) }
    assert_raises( ArgumentError ) { Item.where_tuple(column_set, []) }
    assert_raises( ArgumentError ) { Item.where_tuple(column_set, ['strong']) }
  end

  def test_find_group_by

    i1 = Item.find_by( itemno: 'A')
    i2 = Item.find_by( itemno: 'B')
    i3 = Item.find_by( itemno: 'C')

    is = Item.find_group_by( :itemno => [ 'A', 'B', 'C'], :sizen => [1, 2, 3], :company => [21, 22, 23] )

    assert_not_nil( is )
    assert_equal( 3, is.count)
    assert_includes( is, i1)
    assert_includes( is, i2)
    assert_includes( is, i3)

    is = Item.find_group_by( :itemno => [ 'A', 'B', 'C'], :sizen => [2, 3, 1], :company => [21, 22, 23] )
    assert_not_nil( is )
    assert_equal( 0, is.count)

    is = Item.find_group_by( :itemno => [ 'A', 'B', 'C'], :sizen => [1, 2, 3], :company => [21, 22, 24] )
    assert_not_nil( is )
    assert_equal( 2, is.count)
    assert_includes( is, i1)
    assert_includes( is, i2)

    is = Item.find_group_by( :itemno => [ 'A', 'B', 'C'], :sizen => [1, 2, 3], :company => [23, 23, 23] )
    assert_not_nil( is )
    assert_equal( 1, is.count)
    assert_includes( is, i3)

    is = Item.find_group_by( :itemno => [ 'A', 'A', 'A'], :sizen => [1, 2, 3], :company => [21, 22, 23] )
    assert_equal( 1, is.count)
    assert_includes( is, i1)
  end

  def test_find_by_multiple_columns

    i1 = Item.find_by( itemno: 'A')
    i2 = Item.find_by( itemno: 'B')
    i3 = Item.find_by( itemno: 'C')

    column_set = [ :itemno, :sizen, :company ]
    is = Item.where_tuple( column_set, [ ['A', 1, 21], ['B', 2, 22], ['C', 3, 23] ] )

    assert_not_nil( is )
    assert_equal( 3, is.count)
    assert_equal( i1, is[0])
    assert_equal( i2, is[1])
    assert_equal( i3, is[2])

    is = Item.where_tuple( column_set, [ ['A', 2, 21], ['B', 3, 22], ['C', 1, 23] ] )
    assert_not_nil( is )
    assert_equal( 0, is.count)

    is = Item.where_tuple( column_set, [ ['A', 1, 21], ['B', 2, 22], ['C', 3, 24] ] )
    assert_not_nil( is )
    assert_equal( 2, is.count)
    assert_equal( i1, is[0])
    assert_equal( i2, is[1])

    is = Item.where_tuple( column_set, [ ['A', 1, 23], ['B', 2, 23], ['C', 3, 23] ] )
    assert_not_nil( is )
    assert_equal( 1, is.count)
    assert_equal( i3, is[0])

    is = Item.where_tuple( column_set, [ ['A', 1, 21], ['A', 2, 22], ['A', 3, 23] ] )
    assert_equal( 1, is.count)
    assert_equal( i1, is[0])
  end

end
