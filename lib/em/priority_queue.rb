# encoding: UTF-8

module EventMachine

  # Behaves just like EM::Queue with the exception that items added to the queue
  # are sorted and popped from the queue by their priority. The optional comparator
  # block passed in the constructor determines element priority, with items sorted
  # lowest to highest. If no block is provided, the elements' natural ordering,
  # via <=>, is used.
  #
  # @example
  #
  #  q = EM::PriorityQueue.new do |a, b|
  #    a[:priority] <=> b[:priority]
  #  end
  #  q.push({:priority => 3, :msg => 'three'})
  #  q.push({:priority => 2, :msg => 'two'})
  #  q.push({:priority => 1, :msg => 'one'})
  #  3.times do
  #    q.pop {|item| puts item[:msg] }
  #  end
  #  #=> "one"
  #  #   "two"
  #  #   "three"
  #
  class PriorityQueue < Queue
    def initialize(&comparator)
      super
      @items = Heap.new(&comparator)
    end

    # A binary min heap implementation for efficient storage of queue items. This
    # class implements the Array methods called by EM::Queue so that it may
    # replace the +@items+ instance variable. Namely, +push+ +shift+, +size+, and
    # +empty?+ are implemented.
    class Heap
      def initialize(*items, &comp)
        @heap = []
        @comp = comp || proc {|a, b| a <=> b }
        push(*items)
      end

      def push(*items)
        items.each do |item|
          @heap << item
          move_up(@heap.size - 1)
        end
      end
      alias :<< :push

      def pop
        return if @heap.empty?
        root = @heap[0]
        @heap[0] = @heap[-1]
        @heap.pop
        move_down(0)
        root
      end
      alias :shift :pop

      def size
        @heap.size
      end

      def empty?
        @heap.empty?
      end

      private

      def move_down(k)
        left  = 2 * k + 1
        right = 2 * k + 2
        return if left > (@heap.size - 1)
        smaller = (right < @heap.size && @comp[@heap[right], @heap[left]] < 0) ? right : left
        if @comp[@heap[k], @heap[smaller]] > 0
          @heap[k], @heap[smaller] = @heap[smaller], @heap[k]
          move_down(smaller)
        end
      end

      def move_up(k)
        return if k == 0
        parent = (k - 1) / 2
        if @comp[@heap[k], @heap[parent]] < 0
          @heap[k], @heap[parent] = @heap[parent], @heap[k]
          move_up(parent)
        end
      end
    end
  end
end
