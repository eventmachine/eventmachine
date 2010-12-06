require 'eventmachine'
require 'test/unit'

Test::Unit::TestCase.class_eval do
  def setup_timeout(timeout = 0.5)
    EM.schedule {
      start_time = EM.current_time
      EM.add_periodic_timer(0.01) {
        raise "timeout" if EM.current_time - start_time >= timeout
      }
    }
  end
end
