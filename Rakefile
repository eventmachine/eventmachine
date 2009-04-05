#!/usr/bin/env rake
#--
# Ruby/EventMachine
#   http://rubyeventmachine.com
#   Copyright (C) 2006-07 by Francis Cianfrocca
#
#   This program is copyrighted free software. You may use it under
#   the terms of either the GPL or Ruby's License. See the file
#   COPYING in the EventMachine distribution for full licensing
#   information.
#
# $Id$
#++

### OLD RAKE: ###
# # The tasks and external gemspecs we used to generate binary gems are now
# # obsolete. Use Patrick Hurley's gembuilder to build binary gems for any
# # desired platform.
# # To build a binary gem on Win32, ensure that the include and lib paths
# # both contain the proper references to OPENSSL. Use the static version
# # of the libraries, not the dynamic, otherwise we expose the user to a
# # runtime dependency.
# 
# # To build a binary gem for win32, first build rubyeventmachine.so
# # using VC6 outside of the build tree (the normal way: ruby extconf.rb,
# # and then nmake). Then copy rubyeventmachine.so into the lib directory,
# # and run rake gemwin32.
#

require 'rubygems'  unless defined?(Gem)
require 'rake'      unless defined?(Rake)
require 'rake/gempackagetask'

Package = false # Build zips and tarballs?
Dir.glob('tasks/*.rake').each { |r| Rake.application.add_import r }

# e.g. rake EVENTMACHINE_LIBRARY=java for forcing java build tasks as defaults!
$eventmachine_library = :java if RUBY_PLATFORM =~ /java/ || ENV['EVENTMACHINE_LIBRARY'] == 'java'
$eventmachine_library = :pure_ruby if ENV['EVENTMACHINE_LIBRARY'] == 'pure_ruby'

MAKE = ENV['MAKE'] || if RUBY_PLATFORM =~ /mswin/ # mingw uses make.
  'nmake'
else
  'make'
end

# If running under rubygems...
__DIR__ ||= File.expand_path(File.dirname(__FILE__))
if Gem.path.map{|path| Dir.chdir(path){ Dir.pwd } rescue path }.any? {|path| %r(^#{Regexp.escape path}) =~ __DIR__}
  task :default => :gem_build
else
  desc "Build gemspec, then build eventmachine, then run tests."
  task :default => [:build, :test]
end

desc ":default build when running under rubygems."
task :gem_build => :build

desc "Build extension (or EVENTMACHINE_LIBRARY) and place in lib"
build_task = 'ext:build'
build_task = 'java:build' if $eventmachine_library == :java
build_task = :dummy_build if $eventmachine_library == :pure_ruby
task :build => build_task do |t|
  Dir.glob('{ext,java/src,ext/fastfilereader}/*.{so,bundle,dll,jar}').each do |f|
    mv f, "lib"
  end
end

task :dummy_build

# Basic clean definition, this is enhanced by imports aswell.
task :clean do
  chdir 'ext' do
    sh "#{MAKE} clean" if test ?e, 'Makefile'
  end
  chdir 'ext/fastfilereader' do
    sh "#{MAKE} clean" if test ?e, 'Makefile'
  end
  Dir.glob('**/Makefile').each { |file| rm file }
  Dir.glob('**/*.{o,so,bundle,class,jar,dll,log}').each { |file| rm file }
  Dir.glob('ext/**/conftest.dSYM').each{ |file| rm_rf file }
end

Spec = Gem::Specification.new do |s|
  s.name              = "eventmachine"
  s.summary           = "Ruby/EventMachine library"
  s.platform          = Gem::Platform::RUBY

  s.has_rdoc          = true
  s.rdoc_options      = %w(--title EventMachine --main README --line-numbers -x lib/em/version -x lib/emva -x lib/evma/ -x lib/pr_eventmachine -x lib/jeventmachine)
  s.extra_rdoc_files  = Dir['README,docs/*']

  s.files             = `git ls-files`.split("\n")

  s.require_path      = 'lib'

  # TODO / XXX - should we enable this? rubygems fails the install if anything 
  # is broken. What we could do is CI submission, though, and always terminate
  # with a positive code...
  # s.test_file         = "tests/testem.rb"

  # XXX Using rake to compile extensions breaks when you have multiple ruby installations
  # and your path isn't set. We can switch back to this once the Gem.exec patch is merged.
  # s.extensions        = "Rakefile"
  s.extensions        = ["ext/extconf.rb", "ext/fastfilereader/extconf.rb"]

  s.author            = "Francis Cianfrocca"
  s.email             = "garbagecat10@gmail.com"
  s.rubyforge_project = 'eventmachine'
  s.homepage          = "http://rubyeventmachine.com"

  # Pulled in from readme, as code to pull from readme was not working!
  # Might be worth removing as no one seems to use gem info anyway.
  s.description = <<-EOD
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
  EOD

  require 'lib/em/version'
  s.version = EventMachine::VERSION
end

if RUBY_PLATFORM =~ /mswin/
  Spec.platform = 'x86-mswin32-60'
  Spec.files += %w[ lib/rubyeventmachine.so lib/fastfilereaderext.so ]
  Spec.extensions = nil
elsif RUBY_PLATFORM =~ /java/
  Spec.platform = 'java'
  Spec.files += %w[ lib/em_reactor.jar ]
  Spec.extensions = nil
end

# this is a hack right now, it requires installing msysgit in the global path so it can use tar/curl/etc.
namespace :win32 do
  task :check_git do
    unless `git` =~ /rebase/
      raise 'git not found, install msys git into the GLOBAL PATH: http://msysgit.googlecode.com/files/Git-1.6.2-preview20090308.exe'
    end
  end

  task :check_vc6 do
    begin
      raise unless `nmake 2>&1` =~ /Microsoft/
    rescue
      raise 'VC6 not found, please run c:\vc\setvc.bat vc6'
    end
  end

  task :check_perl do
    unless `perl --version` =~ /ActiveState/
      raise 'ActiveState perl required to build OpenSSL: http://downloads.activestate.com/ActivePerl/Windows/5.10/ActivePerl-5.10.0.1004-MSWin32-x86-287188.msi'
    end
  end

  task :build_openssl => [:check_git, :check_perl, :check_vc6] do
    mkdir_p 'build'
    chdir 'build' do
      unless File.exists?('openssl-0.9.8j')
        sh 'curl http://www.openssl.org/source/openssl-0.9.8j.tar.gz > openssl.tar.gz'
        sh 'tar zxvf openssl.tar.gz' rescue nil # fails because of symlinks
      end

      mkdir_p 'local'
      chdir 'openssl-0.9.8j' do
        sh "perl Configure VC-WIN32 --prefix=\"../local/\""
        sh 'ms\do_ms.bat'
        sh 'nmake -f ms\nt.mak install'
      end

      chdir '../ext' do
        sh 'git clean -fd .'
      end

      mv 'local/include/openssl', '../ext/'
      mv 'local/lib/ssleay32.lib', '../ext/'
      mv 'local/lib/libeay32.lib', '../ext/'
    end
  end

  desc "build binary win32 gem"
  task :gem => :build_openssl do
    Rake::Task['build'].invoke
    Rake::Task['gem'].invoke
  end
end

namespace :ext do
  ext_sources = FileList['ext/*.{h,cpp,rb,c}']
  ffr_sources = FileList['ext/fastfilereader/*.{h,cpp,rb}']
  
  desc "Build C++ extension"
  task :build => [:make]
  
  desc "make extensions"
  task :make => ext_sources + ['ext/Makefile'] do
    chdir 'ext' do
      sh MAKE
    end
  end
  task :make => ffr_sources + ['ext/fastfilereader/Makefile'] do
    chdir 'ext/fastfilereader' do
      sh MAKE
    end
  end
  
  desc 'Compile the makefile'
  file 'ext/Makefile' => ext_sources do
    chdir 'ext' do
      ruby 'extconf.rb'
    end
  end

  desc 'Compile fastfilereader makefile'
  file 'ext/fastfilereader/Makefile' => ffr_sources do
    chdir 'ext/fastfilereader' do
      ruby 'extconf.rb'
    end
  end
end

namespace :java do
  # This task creates the JRuby JAR file and leaves it in the lib directory.
  # This step is required before executing the jgem task.
  desc "Build java extension"
  task :build => [:jar] do |t|
    chdir('java/src') do
      mv 'em_reactor.jar', '../../lib/em_reactor.jar'
    end
  end
  
  desc "compile .java to .class"
  task :compile do
    chdir('java/src') do
      sh 'javac com/rubyeventmachine/*.java'
    end
  end
  
  desc "compile .classes to .jar"
  task :jar => [:compile] do
    chdir('java/src') do
      sh "jar -cf em_reactor.jar com/rubyeventmachine/*.class"
    end
  end

  desc "build a java binary gem"
  task :gem => :build do
    Rake::Task['gem'].invoke
  end
end

task :gemspec => :clobber do
  open("eventmachine.gemspec", 'w') { |f| f.write Spec.to_ruby }
end

task :clobber => :clean
task :test => :build