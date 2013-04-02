# -*- encoding: utf-8 -*-
if RUBY_VERSION == "1.8.7"
  $:.unshift File.expand_path("../lib", __FILE__)
  require "em/version"
else
  # Ruby 1.9.
  require File.expand_path("../lib/em/version", __FILE__)
end

Gem::Specification.new do |s|
  s.name = "eventmachine-le"
  s.version = EventMachine::VERSION
  s.homepage = "https://github.com/ibc/EventMachine-LE/"
  s.licenses = ["Ruby", "GPL"]

  s.authors = ["Francis Cianfrocca", "Aman Gupta", "hacked by Carsten Bormann and Inaki Baz Castillo"]
  s.email   = ["garbagecat10@gmail.com", "aman@tmm1.net", "cabo@tzi.org", "ibc@aliax.net"]

  s.files = `git ls-files`.split("\n")
  s.extensions = ["ext/extconf.rb", "ext/fastfilereader/extconf.rb"]

  s.required_ruby_version = ">= 1.8.7"
  s.add_development_dependency "rake-compiler", ">= 0.7.9"
  s.add_development_dependency "yard", ">= 0.7.2"
  s.add_development_dependency "bluecloth"

  s.summary = "EventMachine LE (Live Edition)"
  s.description = "EventMachine-LE (Live Edition) is a branch of EventMachine (https://github.com/eventmachine/eventmachine).

This branch incorporates interesting pull requests that are not yet included in the mainline EventMachine repository. The maintainers of that version prefer to minimize change in order to keep the stability with already existing EventMachine deployments, which provides an impressive multi-platform base for IPv4 TCP servers (e.g., Web servers) that don't need good UDP or IPv6 support.

This dedication to stability is helpful for production use, but can also lead to ossification. The present \"Live Edition\" or \"Leading Edge\" branch has its focus on supporting a somewhat wider use, including new Web servers or protocols beyond the HTTP Web.

To provide even more focus, this branch is currently applying its energy towards Linux and Unix/BSD/OSX environments. Java reactor and pure Ruby reactor are for now removed in this branch, and Windows/Cygwin support is untested. This may very well change later, once interesting pull requests come in.

EventMachine-LE draws from a number of dormant pull requests on the mainline version of EventMachine. New proposals will also directly come to EventMachine-LE and will be included once they are tested.

This is not a \"development branch\", EventMachine-LE is ready for production, just beyond the focus of mainline EventMachine.
"

  s.rdoc_options = ["--title", "EventMachine-LE", "--main", "README.md", "-x", "lib/em/version"]
  s.extra_rdoc_files = ["README.md"] + `git ls-files`.split("\n")
end
