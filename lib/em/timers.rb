module EventMachine
  # Creates a one-time timer
  #
  #  timer = EventMachine::Timer.new(5) do
  #    # this will never fire because we cancel it
  #  end
  #  timer.cancel
  #
  class Timer
    # Create a new timer that fires after a given number of seconds
    def initialize interval, callback=nil, &block
      @signature = EventMachine::add_timer(interval, callback || block)
    end

    # Cancel the timer
    def cancel
      EventMachine.send :cancel_timer, @signature
    end
  end

  # Creates a periodic timer
  #
  #  n = 0
  #  timer = EventMachine::PeriodicTimer.new(5) do
  #    puts "the time is #{Time.now}"
  #    timer.cancel if (n+=1) > 5
  #  end
  #
  class PeriodicTimer
    # Create a new periodic timer that executes every interval seconds
    def initialize interval, callback=nil, &block
      @interval = interval
      @code = callback || block
      @cancelled = false
      @work = method(:fire)
      schedule
    end

    # Cancel the periodic timer
    def cancel
      @cancelled = true
    end

    # Fire the timer every interval seconds
    attr_accessor :interval

    def schedule # :nodoc:
      EventMachine::add_timer @interval, @work
    end
    def fire # :nodoc:
      unless @cancelled
        @code.call
        schedule
      end
    end
  end

  # Creates a restartable timer
  #
  #  puts "started timer at #{Time.now}"
  #  timer = EventMachine::RestartableTimer.new(5) do
  #    # should be about 7 seconds later, due to restart at 2 seconds
  #    puts "completed timer at #{Time.now}"
  #  end
  #  EventMachine::Timer.new(2) { timer.restart }
  #
  class RestartableTimer < Timer
    def initialize(interval, callback=nil, &block)
      @interval = interval
      @code = callback || block
      @work = method(:fire)
      schedule
    end

    # Restart the timer
    def restart
      cancel
      schedule
    end

    def schedule
      @signature = EventMachine::add_timer(@interval, @work)
    end

    def fire
      @code.call
    end
  end

end
