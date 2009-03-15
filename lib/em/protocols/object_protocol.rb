module EventMachine
  module Protocols
    # ObjectProtocol allows for easy communication using marshaled ruby objects
    #
    #  module RubyServer
    #    include EM::P::ObjectProtocol
    #
    #    def receive_object obj
    #      send_object({'you said' => obj})
    #    end
    #  end
    #
    module ObjectProtocol
      def receive_data data # :nodoc:
        (@buf ||= '') << data

        while @buf.size >= 4
          if @buf.size >= 4+(size=@buf.unpack('N').first)
            @buf.slice!(0,4)
            receive_object Marshal.load(@buf.slice!(0,size))
          else
            break
          end
        end
      end

      # Invoked with ruby objects received over the network
      def receive_object obj
        # stub
      end

      # Sends a ruby object over the network
      def send_object obj
        data = Marshal.dump(obj)
        send_data [data.respond_to?(:bytesize) ? data.bytesize : data.size, data].pack('Na*')
      end
    end
  end
end
