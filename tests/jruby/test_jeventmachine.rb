if !(RUBY_PLATFORM =~ /java/)
  puts "Ignoring tests in #{__FILE__}.  They must be run in JRuby "
else
  require 'test/unit'
  require 'jeventmachine'

  class TestJEventmachine < Test::Unit::TestCase

    def setup
      EventMachine.instance_variable_set("@em", nil)
      load 'jeventmachine.rb'
    end

    def test_can_make_calls_without_errors_before_initialization
      assert_equal nil, EventMachine.signal_loopbreak
      assert_equal nil, EventMachine.stop_tcp_server(123)
      assert_equal nil, EventMachine.send_data(123, "rewr", 4)
      assert_equal nil, EventMachine.close_connection(332, nil)
    end

    def test_create
      EventMachine::initialize_event_machine
      em = EventMachine::instance_variable_get("@em")
      assert_equal true, em.is_a?(Java::com.rubyeventmachine.EmReactor)
    end

    def test_can_make_calls_without_errors_after_release
      EventMachine.initialize_event_machine
      EventMachine.release_machine

      assert_equal nil, EventMachine.signal_loopbreak
      assert_equal nil, EventMachine.stop_tcp_server(123)
      assert_equal nil, EventMachine.send_data(123, "rewr", 4)
      assert_equal nil, EventMachine.close_connection(332, nil)
    end

  end
end
