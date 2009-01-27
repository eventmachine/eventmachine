# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{eventmachine}
  s.version = "0.12.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Francis Cianfrocca"]
  s.date = %q{2009-01-27}
  s.description = %q{EventMachine implements a fast, single-threaded engine for arbitrary network communications. It's extremely easy to use in Ruby. EventMachine wraps all interactions with IP sockets, allowing programs to concentrate on the implementation of network protocols. It can be used to create both network servers and clients. To create a server or client, a Ruby program only needs to specify the IP address and port, and provide a Module that implements the communications protocol. Implementations of several standard network protocols are provided with the package, primarily to serve as examples. The real goal of EventMachine is to enable programs to easily interface with other programs using TCP/IP, especially if custom protocols are required.}
  s.email = %q{garbagecat10@gmail.com}
  s.extensions = ["Rakefile"]
  s.extra_rdoc_files = ["docs/ChangeLog", "docs/COPYING", "docs/DEFERRABLES", "docs/EPOLL", "docs/GNU", "docs/INSTALL", "docs/KEYBOARD", "docs/LEGAL", "docs/LIGHTWEIGHT_CONCURRENCY", "docs/PURE_RUBY", "docs/README", "docs/RELEASE_NOTES", "docs/SMTP", "docs/SPAWNED_PROCESSES", "docs/TODO"]
  s.files = ["Rakefile", "tests/test_attach.rb", "tests/test_basic.rb", "tests/test_defer.rb", "tests/test_epoll.rb", "tests/test_errors.rb", "tests/test_eventables.rb", "tests/test_exc.rb", "tests/test_futures.rb", "tests/test_hc.rb", "tests/test_httpclient.rb", "tests/test_httpclient2.rb", "tests/test_kb.rb", "tests/test_ltp.rb", "tests/test_ltp2.rb", "tests/test_next_tick.rb", "tests/test_processes.rb", "tests/test_pure.rb", "tests/test_running.rb", "tests/test_sasl.rb", "tests/test_send_file.rb", "tests/test_servers.rb", "tests/test_smtpclient.rb", "tests/test_smtpserver.rb", "tests/test_spawn.rb", "tests/test_ssl_args.rb", "tests/test_timers.rb", "tests/test_ud.rb", "tests/testem.rb", "lib/em", "lib/em/deferrable.rb", "lib/em/eventable.rb", "lib/em/future.rb", "lib/em/messages.rb", "lib/em/processes.rb", "lib/em/spawnable.rb", "lib/em/streamer.rb", "lib/eventmachine.rb", "lib/eventmachine_version.rb", "lib/evma", "lib/evma/callback.rb", "lib/evma/container.rb", "lib/evma/factory.rb", "lib/evma/protocol.rb", "lib/evma/reactor.rb", "lib/evma.rb", "lib/jeventmachine.rb", "lib/pr_eventmachine.rb", "lib/protocols", "lib/protocols/buftok.rb", "lib/protocols/header_and_content.rb", "lib/protocols/httpcli2.rb", "lib/protocols/httpclient.rb", "lib/protocols/line_and_text.rb", "lib/protocols/linetext2.rb", "lib/protocols/postgres.rb", "lib/protocols/saslauth.rb", "lib/protocols/smtpclient.rb", "lib/protocols/smtpserver.rb", "lib/protocols/stomp.rb", "lib/protocols/tcptest.rb", "ext/binder.cpp", "ext/binder.h", "ext/cmain.cpp", "ext/cplusplus.cpp", "ext/ed.cpp", "ext/ed.h", "ext/em.cpp", "ext/em.h", "ext/emwin.cpp", "ext/emwin.h", "ext/epoll.cpp", "ext/epoll.h", "ext/eventmachine.h", "ext/eventmachine_cpp.h", "ext/extconf.rb", "ext/files.cpp", "ext/files.h", "ext/kb.cpp", "ext/page.cpp", "ext/page.h", "ext/pipe.cpp", "ext/project.h", "ext/rubymain.cpp", "ext/sigs.cpp", "ext/sigs.h", "ext/ssl.cpp", "ext/ssl.h", "java/src", "java/src/com", "java/src/com/rubyeventmachine", "java/src/com/rubyeventmachine/Application.java", "java/src/com/rubyeventmachine/Connection.java", "java/src/com/rubyeventmachine/ConnectionFactory.java", "java/src/com/rubyeventmachine/DefaultConnectionFactory.java", "java/src/com/rubyeventmachine/EmReactor.java", "java/src/com/rubyeventmachine/EmReactorException.java", "java/src/com/rubyeventmachine/EventableChannel.java", "java/src/com/rubyeventmachine/EventableDatagramChannel.java", "java/src/com/rubyeventmachine/EventableSocketChannel.java", "java/src/com/rubyeventmachine/PeriodicTimer.java", "java/src/com/rubyeventmachine/tests", "java/src/com/rubyeventmachine/tests/ApplicationTest.java", "java/src/com/rubyeventmachine/tests/ConnectTest.java", "java/src/com/rubyeventmachine/tests/EMTest.java", "java/src/com/rubyeventmachine/tests/TestDatagrams.java", "java/src/com/rubyeventmachine/tests/TestServers.java", "java/src/com/rubyeventmachine/tests/TestTimers.java", "java/src/com/rubyeventmachine/Timer.java", "tasks/cpp.rake", "tasks/project.rake", "tasks/tests.rake", "docs/ChangeLog", "docs/COPYING", "docs/DEFERRABLES", "docs/EPOLL", "docs/GNU", "docs/INSTALL", "docs/KEYBOARD", "docs/LEGAL", "docs/LIGHTWEIGHT_CONCURRENCY", "docs/PURE_RUBY", "docs/README", "docs/RELEASE_NOTES", "docs/SMTP", "docs/SPAWNED_PROCESSES", "docs/TODO"]
  s.has_rdoc = true
  s.homepage = %q{http://rubyeventmachine.com}
  s.rdoc_options = ["--title", "EventMachine", "--main", "docs/README", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{eventmachine}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby/EventMachine library}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
