require File.dirname(__FILE__) + '/emtestext'

module EmTestext
  class << self
    attr_reader :recv_hook_called, :send_hook_called, :test_data, :real_data
    def reset
      @recv_hook_called, @send_hook_called = false, false
      @test_data, @real_data = nil, nil
    end
  end
end