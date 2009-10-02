module EventMachine
  # TODO : examples
  module Test

    # Calls EM.next_tick { EM.stop } when it is unbound.
    module UnbindStopper
      def unbind
        EM.next_tick { EM.stop }
      end
    end

    # Immediately closes it's connection when connection_completed is called.
    module ImmediateCloser
      def connection_completed
        close_connection
      end
    end

    # Immediately closes it's connection when connection_completed is called,
    # then calls EM.next_tick { EM.stop } when unbound.
    module ClosingStopper
      include ImmediateCloser
      include UnbindStopper
    end

    # Schedule a job to perform when the reactor is running.
    def job(&blk)
      EM.next_tick(&blk)
    end

    # For use to run a callback after a number of reactor ticks. Reactor ticks
    # may vary in their runtime, and as such this should not be used as a time
    # delay. This method is best suited to achieve relatively rapid non-sleep
    # based assertions "in some time", for example when calling
    # EM::Server#stop or EM.stop_server, which will complete asynchronously in
    # a short timeframe.
    def in_ticks(n = 3, &b)
      if n == 0
        yield
      else
        job { in_ticks(n - 1, &b) }
      end
    end

    # Run the reactor, the optional block will be scheduled to run after all
    # other scheduled jobs.
    def go(timeout = 1, &blk)
      job(&blk) if blk
      success = true
      EM.run do
        EM.add_timer(timeout) do
          EM.stop
          success = false
        end
      end
      assert success, "Timedout after #{timeout} seconds"
    end

  end
end