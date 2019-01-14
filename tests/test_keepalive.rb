require_relative 'em_test_helper'

class TestKeepalive < Test::Unit::TestCase
  def setup
    assert(!EM.reactor_running?)
    @port = next_port
  end

  def teardown
    assert(!EM.reactor_running?)
  end

  def test_enable_keepalive
    omit_if(!EM.respond_to?(:get_sock_opt))

    # I don't know why "An operation was attempted on something that is not a socket."
    pend('FIXME: this test is broken on Windows') if windows?

    val = nil
    test_module = Module.new do
      define_method :post_init do
        enable_keepalive
        val = get_sock_opt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE
        EM.stop
      end
    end

    EM.run do
      EM.start_server '127.0.0.1', @port
      EM.connect '127.0.0.1', @port, test_module
    end

    # Enabled isn't 1 on all platforms - Mac OS seems to be 8
    # Docs say any non-zero value indicates keepalive is enabled
    assert_not_equal 0, val.unpack('i').first
  end

  def test_enable_keepalive_values
    omit_if(!EM.respond_to?(:get_sock_opt))

    # I don't know why "An operation was attempted on something that is not a socket."
    pend('FIXME: this test is broken on Windows') if windows?

    val, val_idle, val_intvl, val_cnt = nil
    test_module = Module.new do
      define_method :post_init do
        enable_keepalive(5, 10, 15)
        val = get_sock_opt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE

        if defined?(Socket::TCP_KEEPALIVE)
          val_idle = get_sock_opt Socket::IPPROTO_TCP, Socket::TCP_KEEPALIVE
        end
        if defined?(Socket::TCP_KEEPIDLE)
          val_idle = get_sock_opt Socket::IPPROTO_TCP, Socket::TCP_KEEPIDLE
        end
        if defined?(Socket::TCP_KEEPINTVL)
          val_intvl = get_sock_opt Socket::IPPROTO_TCP, Socket::TCP_KEEPINTVL
        end
        if defined?(Socket::TCP_KEEPCNT)
          val_cnt = get_sock_opt Socket::IPPROTO_TCP, Socket::TCP_KEEPCNT
        end

        EM.stop
      end
    end

    EM.run do
      EM.start_server '127.0.0.1', @port
      EM.connect '127.0.0.1', @port, test_module
    end

    # Enabled isn't 1 on all platforms - Mac OS seems to be 8
    # Docs say any non-zero value indicates keepalive is enabled
    assert_not_equal 0, val.unpack('i').first

    # Make sure each of the individual settings was set
    if defined?(Socket::TCP_KEEPIDLE) || defined?(Socket::TCP_KEEPALIVE)
      assert_equal 5, val_idle.unpack('i').first
    end

    if defined?(Socket::TCP_KEEPINTVL)
      assert_equal 10, val_intvl.unpack('i').first
    end

    if defined?(Socket::TCP_KEEPCNT)
      assert_equal 15, val_cnt.unpack('i').first
    end
  end

  def test_disable_keepalive
    omit_if(!EM.respond_to?(:get_sock_opt))

    # I don't know why "An operation was attempted on something that is not a socket."
    pend('FIXME: this test is broken on Windows') if windows?

    val = nil
    test_module = Module.new do
      define_method :post_init do
        enable_keepalive
        disable_keepalive
        val = get_sock_opt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE
        EM.stop
      end
    end

    EM.run do
      EM.start_server '127.0.0.1', @port
      EM.connect '127.0.0.1', @port, test_module
    end

    assert_equal 0, val.unpack('i').first
  end
end
