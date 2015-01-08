require 'em_test_helper'

class TestSentData < Test::Unit::TestCase
  BLOB = '1'*10000
  module SendSocket
    def initialize(test)
      @test = test
    end
    def sent_data
      @test.notified_about_sent_data
      EM.next_tick{ EM.stop }
    end
  end

  module BindSocket
    def receive_data(data)
    end
  end

  def until_full
    unless @send_socket.get_outbound_data_size > 0
      @send_socket.send_data BLOB
      EM.add_timer(0.01, method(:until_full))
    else
      @bind_socket.resume
      @send_socket.notify_sent_data = true
    end
  end

  def notified_about_sent_data
    @notified = true
  end

  def test_sent_data_callback
    EM.run {
      EM.start_server '127.0.0.1', '18881', BindSocket do |sock|
        @bind_socket = sock
        sock.pause
      end
      @send_socket = EM.connect '127.0.0.1', '18881', SendSocket, self
      EM.add_timer(0.01, method(:until_full)) 
    }
    assert @notified
  end
end
