require 'em/worker_queue'
module EventMachine
  Enumerator = if defined? ::Enumerable::Enumerator
                 ::Enumerable::Enumerator
               else
                 ::Enumerator
               end
  Generater  = if defined? ::Generator
                 ::Generator
               else
                 ::Enumerator::Generator
               end

  # A simple iterator for concurrent asynchronous work.
  #
  # Unlike ruby's built-in iterators, the end of the current iteration cycle is signaled manually,
  # instead of happening automatically after the yielded block finishes executing. For example:
  #
  #   (0..10).each{ |num| }
  #
  # becomes:
  #
  #   EM::Iterator.new(0..10).each{ |num,iter| iter.next }
  #
  # This is especially useful when doing asynchronous work via reactor libraries and
  # functions. For example, given a sync and async http api:
  #
  #   response = sync_http_get(url); ...
  #   async_http_get(url){ |response| ... }
  #
  # a synchronous iterator such as:
  #
  #   responses = urls.map{ |url| sync_http_get(url) }
  #   ...
  #   puts 'all done!'
  #
  # could be written as:
  #
  #   EM::Iterator.new(urls).map(proc{ |url,iter|
  #     async_http_get(url){ |res|
  #       iter.return(res)
  #     }
  #   }, proc{ |responses|
  #     ...
  #     puts 'all done!'
  #   })
  #
  # Now, you can take advantage of the asynchronous api to issue requests in parallel. For example,
  # to fetch 10 urls at a time, simply pass in a concurrency of 10:
  #
  #   EM::Iterator.new(urls, 10).each do |url,iter|
  #     async_http_get(url){ iter.next }
  #   end
  #
  class Iterator

    # Create a new parallel async iterator with specified concurrency.
    #
    #   i = EM::Iterator.new(1..100, 10)
    #
    # will create an iterator over the range that processes 10 items at a time. Iteration
    # is started via #each, #map or #inject
    #
    def initialize(list, concurrency = 1)
      raise ArgumentError, 'concurrency must be bigger than zero' unless (concurrency > 0)
      @enum = list
      @concurrency = concurrency
      @worker = nil
    end

    # Change the concurrency of this iterator. Workers will automatically be spawned or destroyed
    # to accomodate the new concurrency level.
    #
    def concurrency=(val)
      @concurrency = val
      @worker.concurrency = val  if @worker
    end
    attr_reader :concurrency

    class EachQueue < WorkerQueue # :nodoc:
      class Worker < WorkerQueue::Worker # :nodoc:
        private :done
        def next
          raise RuntimeError, 'already completed this iteration' if done?
          done
        end
      end

      def initialize(foreach, ondone, concurrency)
        super foreach, ondone, :concurrency => concurrency
      end
    end

    def _iterate
      # We allow generator interface for Enumerator only in Ruby 1.9.x where Fiber is introduced
      if @enum.respond_to?(:next) && (defined?(::Fiber) ||
                                      !(Enumerator === @enum || Generator === @enum))
        @worker.on_empty{
          begin
            @worker.push @enum.next
          rescue StopIteration
            @worker.close
          rescue StandardError => e
            @worker.close
            raise e
          end
        }
        @worker.run
      elsif EM::Queue === @enum
        @worker.on_empty{ @enum.pop{|v| @worker.push v} }
      else
        @enum.each{|args| @worker.push args }
        @worker.close
      end
    end

    # Iterate over a set of items using the specified block or proc.
    #
    #   EM::Iterator.new(1..100).each do |num, iter|
    #     puts num
    #     iter.next
    #   end
    #
    # An optional second proc is invoked after the iteration is complete.
    #
    #   EM::Iterator.new(1..100).each(
    #     proc{ |num,iter| iter.next },
    #     proc{ puts 'all done' }
    #   )
    #
    def each(foreach=nil, after=nil, &blk)
      foreach, after = blk, foreach  if after.nil? && blk
      raise ArgumentError, 'proc or block required for iteration' unless foreach ||= blk
      raise RuntimeError, 'cannot iterate over an iterator more than once' if @worker && @worker.closed?

      @worker = EachQueue.new(foreach, after, @concurrency)
      _iterate
    end

    class MapQueue < WorkerQueue # :nodoc:
      class Worker < WorkerQueue::Worker # :nodoc:
        def initialize(master, value, callback)
          super
          @index = @master._index
        end
        private :done
        def return(value)
          raise RuntimeError, 'already returned a value for this iteration' if done?
          @master._assign(@index, value)
          done
        end
      end

      attr_reader :_index
      def initialize(foreach, after, concurrency)
        @accum = []
        @_index = 0
        _after = proc{ after.call(@accum) }
        super foreach, _after, concurrency
      end

      def _assign(index, value)
        @accum[index] = value
      end

      def spawn_worker(value)
        v = super
        @_index += 1
        v
      end
    end

    # Collect the results of an asynchronous iteration into an array.
    #
    #   EM::Iterator.new(%w[ pwd uptime uname date ], 2).map(proc{ |cmd,iter|
    #     EM.system(cmd){ |output,status|
    #       iter.return(output)
    #     }
    #   }, proc{ |results|
    #     p results
    #   })
    #
    def map(foreach, after = nil, &blk)
      foreach, after = blk, foreach  if after.nil? && blk
      raise ArgumentError, 'proc or block required for iteration' unless foreach ||= blk
      raise ArgumentError, 'EM::Iterator meaningless without after proc' unless after
      raise RuntimeError, 'cannot iterate over an iterator more than once' if @worker && @worker.closed?

      @worker = MapQueue.new(foreach, after, @concurrency)
      _iterate
    end

    class InjectQueue < WorkerQueue # :nodoc:
      class Worker < WorkerQueue::Worker # :nodoc:
        private :done
        def return(value)
          raise RuntimeError, 'already returned a value for this iteration' if done?
          @master._obj = value
          done
        end
        def call
          @callback.call(@master._obj, @value, self)
        end
      end

      attr_accessor :_obj
      def initialize(obj, foreach, after, concurrency)
        @_obj = obj
        _after = proc{ after.call(@_obj) }
        super foreach, _after, concurrency
      end
    end

    # Inject the results of an asynchronous iteration onto a given object.
    #
    #   EM::Iterator.new(%w[ pwd uptime uname date ], 2).inject({}, proc{ |hash,cmd,iter|
    #     EM.system(cmd){ |output,status|
    #       hash[cmd] = status.exitstatus == 0 ? output.strip : nil
    #       iter.return(hash)
    #     }
    #   }, proc{ |results|
    #     p results
    #   })
    #
    def inject(obj, foreach, after = nil, &blk)
      foreach, after = blk, foreach  if after.nil? && blk
      raise ArgumentError, 'proc required for iteration' unless foreach ||= blk
      raise RuntimeError, 'cannot iterate over an iterator more than once' if @worker && @worker.closed?

      @worker = InjectQueue.new(obj, foreach, after, @concurrency)
      _iterate
    end
  end
end

# TODO: pass in one object instead of two? .each{ |iter| puts iter.current; iter.next }
# TODO: support iter.pause/resume/stop/break/continue?
# TODO: create some exceptions instead of using RuntimeError
# TODO: support proc instead of enumerable? EM::Iterator.new(proc{ return queue.pop })
