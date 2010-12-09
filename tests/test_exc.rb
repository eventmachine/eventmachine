require 'em_test_helper'

class TestSomeExceptions < Test::Unit::TestCase

  # Read the commentary in EventMachine#run.
  # This test exercises the ensure block in #run that makes sure
  # EventMachine#release_machine gets called even if an exception is
  # thrown within the user code. Without the ensured call to release_machine,
  # the second call to EventMachine#run will fail with a C++ exception
  # because the machine wasn't cleaned up properly.

  def test_a
    assert_raises(RuntimeError) {
      EventMachine.run {
      raise "some exception"
    }
    }
  end

  def test_b
    assert_raises(RuntimeError) {
      EventMachine.run {
      raise "some exception"
    }
    }
  end

end
