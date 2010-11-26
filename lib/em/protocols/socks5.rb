module EventMachine
  module Protocols
    # Basic SOCKS v5 client implementation
    #
    # Use as you would any regular connection:
    #
    # class MyConn < EM::P::Socks5
    #   def post_init
    #     send_data("sup")
    #   end
    #
    #   def receive_data(data)
    #     send_data("you said: #{data}")
    #   end
    # end
    #
    # EM.connect socks_host, socks_port, MyConn, host, port
    #
    class Socks5 < Connection
      def initialize(host, port)
        @host = host
        @port = port
        @socks_error_code = nil
        @buffer = ''
        @socks_state = :method_negotiation
        @socks_methods = [0] # TODO: other authentication methods
        setup_methods
      end

      def setup_methods
        class << self
          def post_init; socks_post_init; end
          def receive_data(*a); socks_receive_data(*a); end
        end
      end

      def restore_methods
        class << self
          remove_method :post_init
          remove_method :receive_data
        end
      end

      def socks_post_init
        packet = [5, @socks_methods.size].pack('CC') + @socks_methods.pack('C*')
        send_data(packet)
      end

      def socks_receive_data(data)
        @buffer << data

        if @socks_state == :method_negotiation
          return if @buffer.size < 2

          header_resp = @buffer.slice! 0, 2
          _, method_code = header_resp.unpack("cc")

          if @socks_methods.include?(method_code)
            @socks_state = :connecting
            packet = [5, 1, 0].pack("C*")
            
            if @host =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ # IPv4
              packet << [1, $1.to_i, $2.to_i, $3.to_i, $4.to_i].pack("C*")
            elsif @host =~ /^[\da-f\:]+$/i # IPv6
              l, r = if @host =~ /^(.*)::(.*)$/
                [$1,$2].map {|i| i.split ":"}
              else
                [@host.split(":"),[]]
              end
              dec_groups = (l + Array.new(8-l.size-r.size, '0') + r).map {|i| i.hex}
              packet << ([4] + dec_groups).pack("Cn8")
            else # Domain
              packet << [3, @host.length, @host].pack("CCA*")
            end
            packet << [@port].pack("n")

            send_data packet
          else
            @socks_state = :invalid
            @socks_error_code = method_code
            close_connection
            return
          end
        elsif @socks_state == :connecting
          return if @buffer.size < 10

          header_resp = @buffer.slice! 0, 10
          _, response_code, _, address_type, _, _ = header_resp.unpack('CCCCNn')

          if response_code == 0
            @socks_state = :connected
            restore_methods

            post_init
            receive_data(@buffer) unless @buffer.empty?
          else
            @socks_state = :invalid
            @socks_error_code = response_code
            close_connection
            return
          end          
        end
      end
    end
  end
end