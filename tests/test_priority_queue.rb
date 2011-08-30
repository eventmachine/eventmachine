require 'em_test_helper'

class TestEMPriorityQueue < Test::Unit::TestCase
  def test_queue_push
    s = 0
    EM.run do
      q = EM::PriorityQueue.new
      q.push(1)
      EM.next_tick { s = q.size; EM.stop }
    end
    assert_equal 1, s
  end

  def test_queue_pop
    x,y,z = nil
    EM.run do
      q = EM::PriorityQueue.new
      q.push(1,2,3)
      q.pop { |v| x = v }
      q.pop { |v| y = v }
      q.pop { |v| z = v; EM.stop }
    end
    assert_equal 3, x
    assert_equal 2, y
    assert_equal 1, z
  end

  def test_queue_reactor_thread
    q = EM::PriorityQueue.new

    Thread.new { q.push(1,2,3) }.join
    assert q.empty?
    EM.run { EM.next_tick { EM.stop } }
    assert_equal 3, q.size

    x = nil
    Thread.new { q.pop { |v| x = v } }.join
    assert_equal nil, x
    EM.run { EM.next_tick { EM.stop } }
    assert_equal 3, x
  end

  def test_num_waiting
    q = EM::PriorityQueue.new
    many = 3
    many.times { q.pop {} }
    EM.run { EM.next_tick { EM.stop } }
    assert_equal many, q.num_waiting
  end

  def test_queue_push_sorts
    queue = EM::PriorityQueue.new
    nums = (0..10_000).map {|i| rand(10_000) }
    popped = []
    EM.run do
      nums.each {|num| queue.push(num) }
      assert_equal nums.size, queue.size
      (nums.size - 1).times do
        queue.pop {|item| popped << item }
      end
      queue.pop {|item| popped << item; EM.stop }
    end
    assert queue.empty?
    assert_equal 0, queue.size
    assert_equal nums.sort {|a, b| -(a <=> b) }, popped
  end
end
