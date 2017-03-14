#!/usr/bin/env ruby

require 'rubygems' # or use Bundler.setup
require 'eventmachine'

class SimpleChatServer < EM::Connection
  include EM::Protocols::LineText2

  @connected_clients = []
  class << self
    attr_reader :connected_clients
  end

  DM_REGEXP = /^@([a-zA-Z0-9]+)\s*:?\s*(.+)/.freeze

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
    puts "[info] #{@username} has left" if entered_username?
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

  def ask_username
    send_line("[info] Enter your username:")
  end

  #
  # Message handling
  #

  def handle_chat_message(msg)
    if command?(msg)
      handle_command(msg)
    else
      if direct_message?(msg)
        handle_direct_message(msg)
      else
        announce(msg, "#{@username}:")
      end
    end
  end

  def direct_message?(input)
    input =~ DM_REGEXP
  end

  def handle_direct_message(input)
    username, message = parse_direct_message(input)

    if connection = connected_clients.find { |c| c.username == username }
      puts "[dm] @#{@username} => @#{username}"
      connection.send_line("[dm] @#{@username}: #{message}")
    else
      send_line "@#{username} is not in the room. Here's who is: #{usernames.join(', ')}"
    end
  end

  def parse_direct_message(input)
    [$1, $2] if input =~ DM_REGEXP
  end

  #
  # Commands handling
  #

  def command?(input)
    input =~ /(exit|status)$/i
  end

  def handle_command(cmd)
    case cmd
    when /exit$/i then
      self.close_connection
    when /status$/i then
      self.send_line("[chat server] It's #{Time.now.strftime('%H:%M')} and there are #{number_of_connected_clients} people in the room")
    end
  end

  #
  # Helpers
  #

  def announce(msg = nil, prefix = "[chat server]")
    connected_clients.each { |c| c.send_line("#{prefix} #{msg}") } unless msg.empty?
  end

  def number_of_connected_clients
    connected_clients.size
  end

  def other_peers
    connected_clients.reject { |c| self == c }
  end

  def send_line(line)
    send_data("#{line}\n")
  end

  def usernames
    connected_clients.map { |c| c.username }
  end

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
