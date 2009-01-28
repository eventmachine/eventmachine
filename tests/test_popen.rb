require "test/unit"
$:.unshift File.expand_path(File.dirname(__FILE__) + "/../lib")
require 'eventmachine'

class TestPopen < Test::Unit::TestCase
  def test_popen_exit_status
    conn_obj = nil
    EM.run do
      EM.popen("ruby -e 'exit 7'") do |c|
        conn_obj = c
        def c.post_init
          # @init = EM.get_subprocess_status(signature)
        end
        def c.unbind
          @status = EM.get_subprocess_status(signature)
          EM.stop
        end
      end
    end
    assert_equal nil, conn_obj.instance_variable_get(:@init)
    assert_equal 7, conn_obj.instance_variable_get(:@status)
  end
end