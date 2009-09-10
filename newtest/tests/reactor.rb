describe "eventmachine basics" do
  before do
    $test = {}
  end

  it "Reactor.new should work" do
    @reactor = EM::Reactor.new
    @reactor.class.should.equal EM::Reactor
  end

  it "Reactor#signal_loopbreak should work" do
    lambda { @reactor.signal_loopbreak }.should.not.raise
  end

  it "Reactor#run should work" do
    @reactor.run {
      $test[:ran] = true
      @reactor.stop
    }
    $test[:ran].should.equal true
  end

  it "Reactor#add_timer should work" do
    @reactor.run {
      @reactor.add_timer(0.25) {
        $test[:fired] = true
        @reactor.stop
      }
    }
    $test[:fired].should.equal true
  end

  it "Reactor#next_tick should work" do
    @reactor.run {
      @reactor.next_tick {
        $test[:ticked] = true
        @reactor.stop
      }
    }
    $test[:ticked].should.equal true
  end

  it "Multiple reactors" do
    @reactor2 = EM::Reactor.new
    r2blk = proc {
      $test[:r2_running] = true
      $test[:r1_running].should.equal true
      @reactor.stop
    }
    r2tail = proc {
      $test[:r2_running] = false
    }
    r1blk = proc {
      $test[:r1_running] = true
      @reactor2.run(r2blk, r2tail)
    }
    r1tail = proc {
      $test[:r1_running] = false
      @reactor2.stop
    }
    @reactor.run(r1blk, r1tail)
    $test[:r1_running].should.equal false
    $test[:r2_running].should.equal false
  end

end