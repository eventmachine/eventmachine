require 'eventmachine'
require 'test/unit'
require 'rbconfig'
require 'socket'

class Test::Unit::TestCase
  class EMTestTimeout < StandardError ; end

  def setup_timeout(timeout = TIMEOUT_INTERVAL)
    EM.schedule {
      EM.add_timer(timeout) {
        raise EMTestTimeout, "Test was cancelled after #{timeout} seconds."
      }
    }
  end

  def port_in_use?(port, host="127.0.0.1")
    s = TCPSocket.new(host, port)
    s.close
    s
  rescue Errno::ECONNREFUSED
    false
  end

  def next_port
    @@port ||= 9000
    begin
      @@port += 1
    end while port_in_use?(@@port)

    @@port
  end

  # Returns true if the host have a localhost 127.0.0.1 IPv6.
  def self.local_ipv4?
    return @@has_local_ipv4 if defined?(@@has_local_ipv4)
    begin
      socket = Addrinfo.udp("127.0.0.1", 1).connect
      socket.close
      @@has_local_ipv4 = true
    rescue
      @@has_local_ipv4 = false
    end
  end

  # Returns true if the host have a public IPv6 and stores it in
  # @@public_ipv4.
  def self.public_ipv4?
    return @@has_public_ipv4 if defined?(@@has_public_ipv4)
    begin
      socket = Addrinfo.udp("1.2.3.4", 1).connect
      @@public_ipv4 = socket.local_address.ip_address
      socket.close
      @@has_public_ipv4 = true
    rescue
      @@has_public_ipv4 = false
    end
  end
  
  # Returns true if the host have a localhost ::1 IPv6.
  def self.local_ipv6?
    return @@has_local_ipv6 if defined?(@@has_local_ipv6)
    begin
      socket = Addrinfo.udp("::1", 1).connect
      socket.close
      @@has_local_ipv6 = true
    rescue
      @@has_local_ipv6 = false
    end
  end

  # Returns true if the host have a public IPv6 and stores it in
  # @@public_ipv6.
  def self.public_ipv6?
    return @@has_public_ipv6 if defined?(@@has_public_ipv6)
    begin
      socket = Addrinfo.udp("2001::1", 1).connect
      @@public_ipv6 = socket.local_address.ip_address
      socket.close
      @@has_public_ipv6 = true
    rescue
      @@has_public_ipv6 = false
    end
  end

  # Returns an array with the localhost addresses (IPv4 and/or IPv6).
  def local_ips
    return @@local_ips if defined?(@@local_ips)
    @@local_ips = []
    @@local_ips << "127.0.0.1" if self.class.local_ipv4?
    @@local_ips << "::1" if self.class.local_ipv6?
  end
  
  def exception_class
    jruby? ? NativeException : RuntimeError
  end

  module PlatformHelper
    # http://blog.emptyway.com/2009/11/03/proper-way-to-detect-windows-platform-in-ruby/
    def windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
    end

    # http://stackoverflow.com/questions/1342535/how-can-i-tell-if-im-running-from-jruby-vs-ruby/1685970#1685970
    def jruby?
      defined? JRUBY_VERSION
    end
  end

  include PlatformHelper
  extend PlatformHelper

  # Tests run significantly slower on windows. YMMV
  TIMEOUT_INTERVAL = windows? ? 1 : 0.25

  def silent
    backup, $VERBOSE = $VERBOSE, nil
    begin
      yield
    ensure
      $VERBOSE = backup
    end
  end
end
