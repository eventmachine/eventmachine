require 'thread'
require 'rubyeventmachine'

module EventMachine
  class Reactor
    def initialize
      @timers = {}
      @next_tick_mutex = Mutex.new
      @tails = []
    end
    
    def reactor_running?
      @reactor_running
    end
    
    def run blk=nil, tail=nil, &block
      @tails ||= []
      tail and @tails.unshift(tail)

      if reactor_running?
        (b = blk || block) and b.call # next_tick(b)
      else
        @conns = {}
        @acceptors = {}
        @timers = {}
        @wrapped_exception = nil
        @reactor_running = true
        (b = blk || block) and add_timer(0, b)
        if @next_tick_queue && !@next_tick_queue.empty?
          add_timer(0) { signal_loopbreak }
        end
        @reactor_thread = Thread.current
        run_machine
        #release_machine
        raise @wrapped_exception if @wrapped_exception
      end
    end
    
    def machine_stopped
      until @tails.empty?
        @tails.pop.call
      end

      begin
        #release_machine
      ensure
        if @threadpool
          @threadpool.each { |t| t.exit }
          @threadpool.each do |t|
            next unless t.alive?
            # ruby 1.9 has no kill!
            t.respond_to?(:kill!) ? t.kill! : t.kill
          end
          @threadqueue = nil
          @resultqueue = nil
          @threadpool = nil
        end

        @next_tick_queue = []
      end
      @reactor_running = false
      @reactor_thread = nil
    end
    
    def run_deferred_callbacks # :nodoc:
      until (@resultqueue ||= []).empty?
        result,cback = @resultqueue.pop
        cback.call result if cback
      end
    
      @next_tick_queue ||= []
      if (l = @next_tick_queue.length) > 0
        l.times {|i| @next_tick_queue[i].call}
        @next_tick_queue.slice!( 0...l )
      end
    end
    
    def next_tick pr=nil, &block
      raise ArgumentError, "no proc or block given" unless ((pr && pr.respond_to?(:call)) or block)
      @next_tick_mutex.synchronize do
        (@next_tick_queue ||= []) << ( pr || block )
        signal_loopbreak if reactor_running?
      end
    end
    
    def add_timer *args, &block
      interval = args.shift
      code = args.shift || block
      if code
        # check too many timers!
        s = add_oneshot_timer((interval.to_f * 1000).to_i)
        @timers[s] = code
        s
      end
    end
    
  end
  class TCPServer; def unbind; end; end
end

EM = EventMachine