require 'em_test_helper'

class TestSSLEchoData < Test::Unit::TestCase
  def setup
      $dir = File.dirname(File.expand_path(__FILE__)) + '/'
  end

  module SslEchoServer
    def post_init
      start_tls(:private_key_file => $dir+'server.key', :cert_chain_file => $dir+'server.crt')
    end

    def receive_data data
      send_data data
    end

  end

  module SslEchoClient
    def connection_completed
      start_tls
    end

    def ssl_handshake_completed
      send_data $expected_return_data[$index]
      $index += 1
    end

    def receive_data data
      $actual_return_data ||= []
      $actual_return_data << data
      if $index < 10
        send_data $expected_return_data[$index]
        $index += 1
      else
        @stopping_on_purpose = true
        EM.stop
      end
    end

    def unbind
      fail "unexpected socket close" unless @stopping_on_purpose
    end

  end

  def test_ssl_echo_data
    $expected_return_data = (1..10).map {|n| "Hello, world! (#{n})"}
    $index = 0

    EM.run {
      EM.add_timer(12) { fail "TIMEOUT" }
      EM.start_server("127.0.0.1", 9999, SslEchoServer)
      EM.connect("127.0.0.1", 9999, SslEchoClient)
    }

    assert_equal($expected_return_data, $actual_return_data)
  end

end if EM.ssl?
