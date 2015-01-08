require 'em_test_helper'
require 'em/worker_queue'

class TestWorkerQueue < Test::Unit::TestCase
  def test_worker_as_queue
    EM.run {
      result = []
      add_result = proc{|value, task|
        result << value; task.done
      }
      check_result = proc {
          assert_equal [1,2,3], result
          EM.stop
        }
      worker = EM::WorkerQueue.new(add_result, check_result)
      worker.push 1
      worker.push 2
      worker.push 3
      worker.close
    }
  end

  class DetectConcurency
    attr_reader :max
    def initialize
      @max, @workers = 0, 0
    end

    def for_each(value, task)
      @workers += 1
      @max = @workers  if @workers > @max
      EM.add_timer(0.001) do
        @workers -= 1
        task.done
      end
    end
  end

  def detecter
    @detecter ||= DetectConcurency.new
  end

  def test_concurency_level_1
    EM.run {
      worker = EM::WorkerQueue.new(
        detecter.method(:for_each),
        proc{
          assert_equal 1, detecter.max
          EM.stop
        }
      )
      100.times{|i| worker.push(i)}
      worker.close
    }
  end

  def test_concurrency_level_more
    EM.run {
      worker = EM::WorkerQueue.new(
        detecter.method(:for_each),
        proc{
          assert_equal 4, detecter.max
          EM.stop
        },
        :concurrency => 4
      )
      100.times{|i| worker.push(i)}
      worker.close
    }
  end

  def test_change_concurrency
    EM.run {
      worker = EM::WorkerQueue.new(
        detecter.method(:for_each),
        proc{
          assert_equal 4, detecter.max
          EM.stop
        }
      )
      100.times{|i| worker.push(i)}
      EM.add_timer(0.005) {
        worker.concurrency = 4
      }
      worker.close
    }
  end

  def test_pull_queue
    EM.run {
      i = 0
      worker = EM::WorkerQueue.new(
        detecter.method(:for_each),
        proc{
          assert_equal 4, detecter.max
          assert_equal 100, i
          EM.stop
        }
      )
      worker.on_empty{|wq|
        i += 1
        wq.concurrency = 4  if i == 50
        if i == 100
          wq.close
        else
          wq.push i
        end
      }
      worker.run
    }
  end

  def test_worker_with_queue
    result = []
    EM.run {
      q = EM::Queue.new
      q.push 1, 2, 3, 4, 5
      after = proc{ EM.stop }
      on_empty = proc{|wq| q.pop{|v| wq.push v} }
      EM::WorkerQueue.new( :on_empty => on_empty ) { |num, iter|
        result << num
        iter.done
      }
      EM.add_timer(0.01,&after)
    }
    assert_equal (1..5).to_a, result
  end

  def test_worker_with_queue_concurrency
    result = []
    EM.run {
      q = EM::Queue.new
      on_empty = proc{|wq| q.pop{|v| wq.push v} }
      worker = EM::WorkerQueue.new(
        detecter.method(:for_each),
        proc {
          assert_equal 4, detecter.max
          EM.stop
        },
        :on_empty => on_empty,
        :concurrency => 4
      )
      q.push *(1..10)
      EM.add_timer(0.02){ worker.stop }
    }
  end

  def test_worker_with_queue_pushing
    result = []
    EM.run {
      q = EM::Queue.new
      q.push 1, 2, 3, 4, 5
      after = proc{ EM.stop }
      on_empty = proc{|wq| q.pop{|v| wq.push v} }
      EM::WorkerQueue.new( :on_empty => on_empty ){ |num,iter|
        result << num
        iter.done
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
