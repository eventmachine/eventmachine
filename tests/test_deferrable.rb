require 'em_test_helper'

class TestDeferrable < Test::Unit::TestCase
  class Later
    include EM::Deferrable
  end

  def test_timeout_without_args
    $args = "unset"

    EM.run {
      df = Later.new
      df.timeout(0.2)
      df.errback { $args = "none" }
      EM.add_timer(0.5) { EM.stop }
    }

    assert_equal("none", $args)
  end

  def test_timeout_with_args
    $args = "unset"

    EM.run {
      df = Later.new
      df.timeout(0.2, :timeout, :foo)
      df.errback { |type, name| $args = [type, name] }
      EM.add_timer(0.5) { EM.stop }
    }

    assert_equal([:timeout, :foo], $args)
  end
end