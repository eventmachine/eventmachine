module EventMachine
  module Protocols
    # LineProtocol will parse out newline terminated strings from a receive_data stream
    #
    #  module Server
    #    include EM::P::LineProtocol
    #
    #    def receive_line(line)
    #      send_data("you said: #{line}")
    #    end
    #  end
    #
    module LineProtocol
      # @private
      def receive_data data
        (@buf ||= '') << data

        @buf.each_line do |line|
          if line[-1] == "\n"
            receive_line(line.chomp)
          else
            @buf = line
          end
        end
      end

      # Invoked with lines received over the network
      def receive_line(line)
        # stub
      end
    end
  end
end
