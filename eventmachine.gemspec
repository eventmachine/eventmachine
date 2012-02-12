# -*- encoding: utf-8 -*-
require File.expand_path('../lib/em/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'eventmachine-with-ipv6'
  s.version = EventMachine::VERSION
  s.homepage = 'http://github.com/cabo/eventmachine'
#  s.rubyforge_project = 'eventmachine'

  s.authors = ["Francis Cianfrocca", "Aman Gupta", "hacked by Carsten Bormann"]
  s.email   = ["garbagecat10@gmail.com", "aman@tmm1.net", "cabo@tzi.org"]

  s.files = `git ls-files`.split("\n")
  s.extensions = ["ext/extconf.rb", "ext/fastfilereader/extconf.rb"]

  s.add_development_dependency 'rake-compiler', '0.7.9'
  s.add_development_dependency 'yard', ">= 0.7.2"
  s.add_development_dependency 'bluecloth'

  s.summary = 'Ruby/EventMachine library with UDP and IPv6 fixes'
  s.description = "EventMachine implements a fast, single-threaded engine for arbitrary network
communications. It's extremely easy to use in Ruby. EventMachine wraps all
interactions with IP sockets, allowing programs to concentrate on the
implementation of network protocols. It can be used to create both network
servers and clients. To create a server or client, a Ruby program only needs
to specify the IP address and port, and provide a Module that implements the
communications protocol. Implementations of several standard network protocols
are provided with the package, primarily to serve as examples. The real goal
of EventMachine is to enable programs to easily interface with other programs
using TCP/IP, especially if custom protocols are required.

The present alternative version 'eventmachine-with-ipv6' contains some
crucial fixes for datagrams (UDP) and IPv6 developed since 2010 by
Carsten Bormann and Iñaki Baz Castillo.  This is needed for many
applications in 2012, but might detract from the stability achieved
for other typical uses of the base eventmachine.  It is otherwise
identical with base eventmachine.  Install either base eventmachine or
this version eventmachine-with-ipv6.

Please send all bugs in this version to https://github.com/cabo/eventmachine/issues
"

  s.rdoc_options = ["--title", "EventMachine", "--main", "README.md", "-x", "lib/em/version", "-x", "lib/jeventmachine"]
  s.extra_rdoc_files = ["README.md"] + `git ls-files -- docs/*`.split("\n")
end
