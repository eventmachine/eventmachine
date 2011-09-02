#!/usr/bin/env ruby

require 'rubygems' # or use Bundler.setup
require 'eventmachine'

class SimpleChatServer < EM::Connection
  include EM::Protocols::LineText2

  @connected_clients = []
  class << self
    attr_reader :connected_clients
  end

  attr_reader :username

  #
  # EventMachine handlers
  #

  def post_init
    @username = nil

    puts "A client has connected..."
    ask_username
  end

  def unbind
    connected_clients.delete(self)
    puts "A client has left..."
  end

  def receive_line(line)
    if entered_username?
      handle_chat_message(line.strip)
    else
      handle_username(line.strip)
    end
  end

  #
  # Username handling
  #

  def entered_username?
    @username && !@username.empty?
  end

  # entered_username?

  def handle_username(input)
    if input.empty?
      send_line("Blank usernames are not allowed. Try again.")
      ask_username
    else
      @username = input
      connected_clients.push(self)
      other_peers.each { |c| c.send_data("#{@username} has joined the room\n") }
      puts "#{@username} has joined"

      send_line("[info] Ohai, #{@username}")
    end
  end

  # handle_username(input)

  def ask_username
    send_line("[info] Enter your username:")
  end

  # ask_username

  #
  # Message handling
  #

  def handle_chat_message(msg)
    raise NotImplementedError
  end

  #
  # Helpers
  #

  def other_peers
    connected_clients.reject { |c| self == c }
  end

  # other_peers

  def send_line(line)
    send_data("#{line}\n")
  end

  # send_line(line)

  def connected_clients
    self.class.connected_clients
  end
end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("0.0.0.0", 10000, SimpleChatServer)
end
