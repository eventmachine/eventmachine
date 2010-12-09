require 'em_test_helper'

unless RUBY_VERSION >= '1.9.0'
  class TestDeferUsage < Test::Unit::TestCase

    def test_defers
      n = 0
      n_times = 20
      EM.run {
        n_times.times {
          work_proc = proc { n += 1 }
          callback = proc { EM.stop if n == n_times }
          EM.defer work_proc, callback
        }
      }
      assert_equal( n, n_times )
    end

  end
end

