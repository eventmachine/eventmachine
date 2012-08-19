module EventMachine
  class TypedChannel
    def initialize
      @subs = {}
      @uid  = 0
    end

    # Takes any arguments suitable for EM::Callback() and returns a subscriber
    # id for use when unsubscribing.
    #
    # @return [Integer] Subscribe identifier
    # @see #unsubscribe
    def subscribe(*a, &b)
      name = gen_id
      EM.schedule { 
        sub = {}
        sub[:block] = EM::Callback(*a[1..-1], &b) 
        sub[:type] = a[0]
        @subs[name] = sub
      }

      name
    end

    # Removes subscriber from the list.
    #
    # @param [Integer] Subscriber identifier
    # @see #subscribe
    def unsubscribe(name)
      EM.schedule { @subs.delete name }
    end

    # Add items to the channel, which are pushed out to all subscribers.
    def push(*items)
      items = items.dup
      EM.schedule { items.each { |i| @subs.values.each { |s| s[:block].call i if i.is_a? s[:type]} } }
    end
    alias << push

    # Fetches one message from the channel.
    def pop(*a, &b)
      EM.schedule {
        name = subscribe do |*args|
          unsubscribe(name)
          EM::Callback(*a, &b).call(*args)
        end
      }
    end

    private

    # @private
    def gen_id
      @uid += 1
    end
  end
end
