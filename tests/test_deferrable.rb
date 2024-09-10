require_relative 'em_test_helper'

class TestDeferrable < Test::Unit::TestCase
  class Later
    include EM::Deferrable
  end

  def test_timeout_without_args
    pend('FIXME: this test is broken in pure ruby mode') if pure_ruby_mode?
    assert_nothing_raised do
      EM.run {
        df = Later.new
        df.timeout(0)
        df.errback { EM.stop }
        EM.add_timer(0.01) { flunk "Deferrable was not timed out." }
      }
    end
  end

  def test_timeout_with_args
    pend('FIXME: this test is broken in pure ruby mode') if pure_ruby_mode?
    args = nil

    EM.run {
      df = Later.new
      df.timeout(0, :timeout, :foo)
      df.errback do |type, name|
        args = [type, name]
        EM.stop
      end

      EM.add_timer(0.01) { flunk "Deferrable was not timed out." }
    }

    assert_equal [:timeout, :foo], args
  end
end
