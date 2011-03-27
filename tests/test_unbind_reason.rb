require 'em_test_helper'
require 'socket'

class TestUnbindReason < Test::Unit::TestCase
  def test_connect_timeout
    error = nil
    EM.run {
      conn = EM.connect 'google.com', 81, Module.new{ |m|
        m.send(:define_method, :unbind) do |reason|
          error = reason
          EM.stop
        end
      }
      conn.pending_connect_timeout = 0.1
    }
    assert_equal error, Errno::ETIMEDOUT
  end

  def test_connect_refused
    error = nil
    EM.run {
      EM.connect '127.0.0.1', 12388, Module.new{ |m|
        m.send(:define_method, :unbind) do |reason|
          error = reason
          EM.stop
        end
      }
    }
    assert_equal error, Errno::ECONNREFUSED
  end
end
