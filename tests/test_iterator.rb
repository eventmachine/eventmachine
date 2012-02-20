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
end