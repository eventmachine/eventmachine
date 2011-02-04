require 'em_test_helper'

class TestBasic < Test::Unit::TestCase

  def test_a
    EM.run {
      d = EM::DNSResolver.resolve "google.com"
      d.errback { raise }
      d.callback { |r|
        assert r
        EM.stop
      }
    }
  end

  # def test_bad_a
  #   out = nil
  #   EM.run {
  #     d = EM::DNSResolver.resolve "asdfasasdfasdfasdfagoogle.com" #"bayshorenetworks.com"
  #     d.errback { EM.stop }
  #     d.callback {|r| out = r; EM.stop }
  #   }
  #
  #   assert out
  # end


  # def test_a_pair
  #   EM::DnsCache.add_nameservers_from_file
  #   EM::DnsCache.verbose
  #
  #   out = nil
  #
  #   EM.run {
  #     d = EM::DnsCache.resolve "maila.microsoft.com"
  #     d.errback {EM.stop}
  #     d.callback {|r|
  #       out = r
  #       EM.stop
  #     }
  #   }
  #
  #   assert_equal( Array, out.class )
  #   assert_equal( 2, out.length )
  # end
  #
  #
  # # This test causes each request to hit the network because they're all scheduled
  # # before the first one can come back and load the cache. Although a nice mis-feature for
  # # stress testing, it would be nice to fix it someday, perhaps by not kicking off a
  # # request for a particular domain if one is already pending.
  # # Without epoll, this test gets really slow and usually doesn't complete.
  # def test_lots_of_a
  #   EM.epoll
  #   EM::DnsCache.add_nameserver TestNameserver
  #   EM::DnsCache.add_nameserver TestNameserver2
  #   EM::DnsCache.verbose
  #
  #   n = 250
  #   e = 0
  #   s = 0
  #   EM.run {
  #     n.times {
  #       d = EM::DnsCache.resolve "ibm.com"
  #       d.errback {e+=1; n -= 1; EM.stop if n == 0}
  #       d.callback {s+=1; n -= 1; EM.stop if n == 0}
  #     }
  #   }
  #   assert_equal( 0, n)
  #   assert_equal( 250, s)
  # end
  #
  #
  #
  #
  # def test_mx
  #   EM::DnsCache.add_nameserver TestNameserver
  #   EM::DnsCache.verbose
  #
  #   out = nil
  #
  #   EM.run {
  #     d = EM::DnsCache.resolve_mx "steamheat.net"
  #     d.errback {EM.stop}
  #     d.callback {|r|
  #       p r
  #       d = EM::DnsCache.resolve_mx "steamheat.net"
  #       d.errback {EM.stop}
  #       d.callback {|r|
  #         out = r
  #         p r
  #         EM.stop
  #       }
  #     }
  #   }
  #
  #   assert out
  # end
  #
  #
  # # The arrays of addresses we get back from the DnsCache are FROZEN.
  # # That's because the same objects get passed around to any caller that
  # # asks for them. If you need to modify the array, dup it.
  # #
  # def test_freeze
  #   EM::DnsCache.add_nameserver TestNameserver
  #   EM::DnsCache.verbose
  #
  #   out = nil
  #
  #   EM.run {
  #     d = EM::DnsCache.resolve_mx "steamheat.net"
  #     d.errback {EM.stop}
  #     d.callback {|r|
  #       out = r
  #       EM.stop
  #     }
  #   }
  #
  #   assert out
  #   assert( out.length > 0)
  #   assert_raise( TypeError ) {
  #     out.clear
  #   }
  # end
  #
  #
  # def test_local_defs
  #   EM::DnsCache.add_nameserver TestNameserver
  #   EM::DnsCache.verbose
  #
  #   EM::DnsCache.add_cache_entry( :mx, "example.zzz", ["1.2.3.4"], -1 )
  #   out = nil
  #   EM.run {
  #     d = EM::DnsCache.resolve_mx "example.zzz"
  #     d.errback {EM.stop}
  #     d.callback {|r|
  #       out = r
  #       EM.stop
  #     }
  #   }
  #   assert_equal( ["1.2.3.4"], out )
  # end
  #
  # def test_multiple_local_defs
  #   EM::DnsCache.verbose
  #
  #   EM::DnsCache.add_cache_entry( :mx, "example.zzz", ["1.2.3.4", "5.6.7.8"], -1 )
  #   out = nil
  #   EM.run {
  #     d = EM::DnsCache.resolve_mx "example.zzz"
  #     d.errback {EM.stop}
  #     d.callback {|r|
  #       out = r
  #       EM.stop
  #     }
  #   }
  #   assert_equal( ["1.2.3.4","5.6.7.8"], out )
  # end
  #
  # # Adding cache entries where they already exist causes them to be REPLACED.
  # #
  # def test_replace
  #   EM::DnsCache.verbose
  #
  #   EM::DnsCache.add_cache_entry( :mx, "example.zzz", ["1.2.3.4", "5.6.7.8"], -1 )
  #   EM::DnsCache.add_cache_entry( :mx, "example.zzz", ["10.11.12.13"], -1 )
  #   out = nil
  #   EM.run {
  #     d = EM::DnsCache.resolve_mx "example.zzz"
  #     d.errback {EM.stop}
  #     d.callback {|r|
  #       out = r
  #       EM.stop
  #     }
  #   }
  #   assert_equal( ["10.11.12.13"], out )
  # end
  #
  # # We have a facility for storing locally-defined MX records.
  # # The DNS cache has a way to parse and process these values.
  # #
  # def test_external_mx_defs
  #   EM::DnsCache.verbose
  #
  #   EM::DnsCache.parse_local_mx_records LocalMxRecords
  #
  #   out = nil
  #   EM.run {
  #     d = EM::DnsCache.resolve_mx "boondoggle.zzz"
  #     d.errback {EM.stop}
  #     d.callback {|r|
  #       out = r
  #       EM.stop
  #     }
  #   }
  #   assert_equal( ["esmtp.someone.zzz", "55.56.57.58", "65.66.67.68"], out )
  # end

end