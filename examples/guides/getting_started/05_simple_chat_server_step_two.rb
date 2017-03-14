#!/usr/bin/env ruby

require 'rubygems' # or use Bundler.setup
require 'eventmachine'

class SimpleChatServer < EM::Connection

  @connected_clients = []
  class << self
    attr_reader :connected_clients
  end

  #
  # EventMachine handlers
  #

  def post_init
    connected_clients.push(self)
    puts "A client has connected..."
  end

  def unbind
    connected_clients.delete(self)
    puts "A client has left..."
  end

  #
  # Helpers
  #

  def other_peers
    connected_clients.reject { |c| self == c }
  end # other_peers

  def connected_clients
    self.class.connected_clients
  end
end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap("INT")  { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("0.0.0.0", 10000, SimpleChatServer)
end
