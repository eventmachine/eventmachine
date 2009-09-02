describe "eventmachine basics" do
  it "Reactor.new should work" do
    @reactor = EM::Reactor.new
    @reactor.class.should.equal EM::Reactor
  end
  
  it "Reactor#signal_loopbreak should work" do
    lambda { @reactor.signal_loopbreak }.should.not.raise
  end
  
  it "Reactor#run should work" do
    @ran = false
    @reactor.run {
      @ran = true
      @reactor.stop
    }
    @ran.should.equal true
  end
  
  it "Reactor#add_timer should work" do
    @fired = false
    @reactor.run {
      @reactor.add_timer(0.25) {
        @fired = true
        @reactor.stop
      }
    }
    @fired.should.equal true
  end
  
  it "Reactor#next_tick should work" do
    @ticked = false
    @reactor.run {
      @reactor.next_tick {
        @ticked = true
        @reactor.stop
      }
    }
    @ticked.should.equal true
  end
  
  it "Multiple reactors" do
    @reactor2 = EM::Reactor.new
    r2blk = proc {
      @r2_running = true
      @r1_running.should.equal true
      @reactor.stop
    }
    r2tail = proc {
      @r2_running = false
    }
    r1blk = proc {
      @r1_running = true
      @reactor2.run(r2blk, r2tail)
      }
    r1tail = proc {
      @r1_running = false
      @reactor2.stop
    }
    @reactor.run(r1blk, r1tail)
    @r1_running.should.equal false
    @r2_running.should.equal false
  end
  
end