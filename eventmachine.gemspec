require File.expand_path('../lib/em/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'eventmachine'
  s.version = EventMachine::VERSION
  s.homepage = 'http://rubyeventmachine.com'
  s.licenses = ['Ruby', 'GPL-2.0']
  s.required_ruby_version = '>= 2.0.0'

  s.authors = ["Francis Cianfrocca", "Aman Gupta"]
  s.email   = ["garbagecat10@gmail.com", "aman@tmm1.net"]

  s.files = `git ls-files README.md CHANGELOG.md GNU LICENSE rakelib ext java lib docs`.split
  s.test_files = `git ls-files tests examples`.split

  s.extensions = ["ext/extconf.rb", "ext/fastfilereader/extconf.rb"]

  if s.respond_to?(:metadata=)
    s.metadata ||= {}
    s.metadata["msys2_mingw_dependencies"] = "openssl"
  end

  s.add_development_dependency 'test-unit', '~> 3.2'
  s.add_development_dependency 'rake-compiler', '~> 1.0'
  s.add_development_dependency 'rake-compiler-dock', '~> 0.6.3'

  s.summary = 'Ruby/EventMachine library'
  s.description = <<-EOT
EventMachine implements a fast, single-threaded engine for arbitrary network
communications. It's extremely easy to use in Ruby. EventMachine wraps all
interactions with IP sockets, allowing programs to concentrate on the
implementation of network protocols. It can be used to create both network
servers and clients. To create a server or client, a Ruby program only needs
to specify the IP address and port, and provide a Module that implements the
communications protocol. Implementations of several standard network protocols
are provided with the package, primarily to serve as examples. The real goal
of EventMachine is to enable programs to easily interface with other programs
using TCP/IP, especially if custom protocols are required.
EOT

  s.rdoc_options = ["--title", "EventMachine", "--main", "README.md", "-x", "lib/em/version", "-x", "lib/jeventmachine"]
  s.extra_rdoc_files = `git ls-files README.md docs`.split
end
