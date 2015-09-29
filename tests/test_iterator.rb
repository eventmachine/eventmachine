require 'em_test_helper'

class TestIterator < Test::Unit::TestCase

  def get_time
    EM.current_time.strftime('%H:%M:%S')
  end

  def test_default_concurrency
    items = {}
    list = 1..10
    EM.run {
      EM::Iterator.new(list).each( proc {|num,iter|
        time = get_time
        items[time] ||= []
        items[time] << num
        EM::Timer.new(1) {iter.next}
      }, proc {EM.stop})
    }
    assert_equal(10, items.keys.size)
    assert_equal(list.to_a.sort, items.values.flatten.sort)
  end

  def test_default_concurrency_with_a_proc
    items = {}
    list = (1..10).to_a
    original_list = list.dup
    EM.run {
      EM::Iterator.new(proc{list.pop || EM::Iterator::Stop}).each( proc {|num,iter|
        time = get_time
        items[time] ||= []
        items[time] << num
        EM::Timer.new(1) {iter.next}
      }, proc {EM.stop})
    }
    assert_equal(10, items.keys.size)
    assert_equal(original_list.to_a.sort, items.values.flatten.sort)
  end

  def test_concurrency_bigger_than_list_size
    items = {}
    list = [1,2,3]
    EM.run {
      EM::Iterator.new(list,10).each(proc {|num,iter|
        time = get_time
        items[time] ||= []
        items[time] << num
        EM::Timer.new(1) {iter.next}
      }, proc {EM.stop})
    }
    assert_equal(1, items.keys.size)
    assert_equal(list.to_a.sort, items.values.flatten.sort)
  end


  def test_changing_concurrency_affects_active_iteration
    items = {}
    list = 1..25
    EM.run {
      i = EM::Iterator.new(list,5)
      i.each(proc {|num,iter|
        time = get_time
        items[time] ||= []
        items[time] << num
        EM::Timer.new(1) {iter.next}
      }, proc {EM.stop})
      EM.add_timer(1){
        i.concurrency = 1
      }
      EM.add_timer(3){
        i.concurrency = 3
      }
    }
    assert_equal(9, items.keys.size)
    assert_equal(list.to_a.sort, items.values.flatten.sort)
  end

  def test_map
    list = 100..150
    EM.run {
      EM::Iterator.new(list).map(proc{ |num,iter|
        EM.add_timer(0.01){ iter.return(num) }
      }, proc{ |results|
        assert_equal(list.to_a.size, results.size)
       EM.stop
      })
    }
  end

  def test_inject
    omit_if(windows?)

    list = %w[ pwd uptime uname date ]
    EM.run {
      EM::Iterator.new(list, 2).inject({}, proc{ |hash,cmd,iter|
        EM.system(cmd){ |output,status|
          hash[cmd] = status.exitstatus == 0 ? output.strip : nil
          iter.return(hash)
        }
      }, proc{ |results|
        assert_equal(results.keys.sort, list.sort)
        EM.stop
      })
    }
  end

  def test_concurrency_is_0
    EM.run {
      assert_raise ArgumentError do
        EM::Iterator.new(1..5,0)
      end
      EM.stop
    }
  end
end
