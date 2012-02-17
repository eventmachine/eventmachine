require 'em_test_helper'
require 'minitest/spec'

class TestEnumerable
  include Enumerable

  def each
    while (num = rand(20)) != 10 do
      yield num
    end
  end
end

describe EventMachine::Iterator do
  it "should go on" do
    EM::Iterator.new(0..10).each{ |num,iter| iter.next }
  end

  it "should works with lazy enumerable" do
    en = TestEnumerable.new
    EM::Iterator.new(en).each{ |num, iter| iter.next }
  end
end