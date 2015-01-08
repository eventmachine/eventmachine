# Copyright Petr Ianovich aka fl00r
# https://github.com/fl00r
require 'em_test_helper'

class TestEnumerable
  include Enumerable

  def each
    while (num = rand(20)) != 10 do
      yield num
    end
  end
end

class TestEnumerable2
  include Enumerable

  def each
    arr = ('a'..'g').to_a
    while it = arr.shift do
      yield it
    end
  end
end

class TestEnumerable3
  include Enumerable

  def each
    ('a'..'f').each.with_index do |ltr, index|
      break if ltr == 'e'
      eval("@#{ltr} = #{index}")
      yield ltr
    end
  end
end

class TestIterator < Test::Unit::TestCase

  def test_iterator_with_array
    assert_nothing_raised do
      EM.run {
        after = proc{ EM.stop }
        EM::Iterator.new(0..10, 10).each(nil, after){ |num,iter| iter.next }
      }
    end
  end

  def test_iterator_with_array_with_result
    nums = []
    EM.run {
      after = proc{ EM.stop }
      EM::Iterator.new((0..10)).each(nil, after){ |num,iter|
        nums << num
        iter.next
      }
    }
    res = (0..10).to_a
    assert_equal res, nums
  end

  def test_iterator_map_with_array
    assert_nothing_raised do
      EM.run {
        after = proc{|ar|
          assert_equal [1,2,3,4,5,6,7,8,9,10,11], ar
          EM.stop
        }
        EM::Iterator.new(0..10, 10).map(after){ |num,iter| iter.return(num+1) }
      }
    end
  end

  def test_iterator_inject_with_array
    assert_nothing_raised do
      EM.run {
        after = proc{|sum|
          assert_equal (0..10).inject(0){|s,i| s+i}, sum
          EM.stop
        }
        EM::Iterator.new(0..10, 10).inject(0, after){ |sum, num, iter|
          iter.return(sum + num)
        }
      }
    end
  end

  def test_iterator_with_enumerable
    assert_nothing_raised do
      EM.run {
        en = TestEnumerable.new
        after = proc{ EM.stop }
        EM::Iterator.new(en, 10).each(nil, after){ |num, iter| iter.next }
      }
    end
  end

  def test_iterator_with_enumerable_with_result
    letters = []
    EM.run {
      en = TestEnumerable2.new
      after = proc{ EM.stop }
      EM::Iterator.new(en, 10).each(nil, after){ |ltr,iter|
        letters << ltr
        iter.next
      }
    }
    res = ('a'..'g').to_a
    assert_equal res, letters
  end

  def test_iterator_with_array_with_nils
    nums = []
    EM.run {
      after = proc{ EM.stop }
      EM::Iterator.new(["Hello", nil, "World", nil]).each(nil, after){ |num,iter|
        nums << num
        iter.next
      }
    }
    res = "Hello World"
    assert_equal res, nums.compact.join(" ")
  end

  def test_iterator_for_lazyness
    enumerable = TestEnumerable3.new
    enumerator = enumerable.to_enum
    EM.run {
      after = proc{ EM.stop }
      EM::Iterator.new(enumerator).each(nil, after){ |num,iter|
        iter.next
      }
    }
    assert_equal 0, enumerable.instance_variable_get(:@a)
    assert_equal 3, enumerable.instance_variable_get(:@d)
    assert_equal false, enumerable.instance_variable_defined?(:@e)
  end

  def test_iterator_with_queue
    result = []
    EM.run {
      q = EM::Queue.new
      q.push 1, 2, 3, 4, 5
      after = proc{ EM.stop }
      EM::Iterator.new(q).each{ |num,iter|
        result << num
        iter.next
      }
      EM.add_timer(0.01,&after)
    }
    assert_equal (1..5).to_a, result
  end

  def test_with_queue_with_pushing
    result = []
    EM.run {
      q = EM::Queue.new
      q.push 1, 2, 3, 4, 5
      after = proc{ EM.stop }
      EM::Iterator.new(q).each{ |num,iter|
        result << num
        iter.next
      }
      q.push 6,7,8
      # and after some time
      push_to_queue = proc{ q.push 9,10}
      EM.add_timer(0.01,&push_to_queue)
      # stop this infinite Iterator
      EM.add_timer(0.02,&after)
    }
    assert_equal (1..10).to_a, result
  end
end
