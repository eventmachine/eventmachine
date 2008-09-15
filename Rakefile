#! /usr/bin/env rake
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


require 'rake/gempackagetask'
require 'rake/clean'


$can_minitar = false
begin
  require 'archive/tar/minitar'
  require 'zlib'
  $can_minitar  = true
rescue LoadError
end

$: << "lib"
require 'eventmachine_version'
$version = EventMachine::VERSION
$distdir  = "eventmachine-#$version"
$tardist  = "#$distdir.tar.gz"
$name = "eventmachine"


# The tasks and external gemspecs we used to generate binary gems are now
# obsolete. Use Patrick Hurley's gembuilder to build binary gems for any
# desired platform.
# To build a binary gem on Win32, ensure that the include and lib paths
# both contain the proper references to OPENSSL. Use the static version
# of the libraries, not the dynamic, otherwise we expose the user to a
# runtime dependency.

=begin
# To build a binary gem for win32, first build rubyeventmachine.so
# using VC6 outside of the build tree (the normal way: ruby extconf.rb,
# and then nmake). Then copy rubyeventmachine.so into the lib directory,
# and run rake gemwin32.
specwin32 = eval(File.read("eventmachine-win32.gemspec"))
specwin32.version = $version
desc "Build the RubyGem for EventMachine-win32"
task :gemwin32 => ["pkg/eventmachine-win32-#{$version}.gem"]
Rake::GemPackageTask.new(specwin32) do |g|
  if $can_minitar
    g.need_tar    = false
    g.need_zip    = false
  end
  g.package_dir = "pkg"
end


# To build a binary gem for unix platforms, first build rubyeventmachine.so
# using gcc outside of the build tree (the normal way: ruby extconf.rb,
# and then make). Then copy rubyeventmachine.so into the lib directory,
# and run rake gembinary.
specbinary = eval(File.read("eventmachine-binary.gemspec"))
specbinary.version = $version
desc "Build the RubyGem for EventMachine-Binary"
task :gembinary => ["pkg/eventmachine-binary-#{$version}.gem"]
Rake::GemPackageTask.new(specbinary) do |g|
  if $can_minitar
    g.need_tar    = false
    g.need_zip    = false
  end
  g.package_dir = "pkg"
end


spec = eval(File.read("eventmachine.gemspec"))
=end

spec = Gem::Specification.new do |s|
	s.name              = "eventmachine"
	s.summary           = "Ruby/EventMachine library"
	s.platform          = Gem::Platform::RUBY

	s.has_rdoc          = true
	s.rdoc_options      = %w(--title EventMachine --main README --line-numbers)
	s.extra_rdoc_files = ["README",
				"RELEASE_NOTES",
				"COPYING",
				"EPOLL",
				"GNU",
				"LEGAL",
				"TODO",
				"KEYBOARD",
				"LIGHTWEIGHT_CONCURRENCY",
				"PURE_RUBY",
				"SMTP",
				"SPAWNED_PROCESSES",
				"DEFERRABLES"
				]

	s.files             = FileList["{bin,tests,lib,ext}/**/*"].exclude("rdoc").to_a

	s.require_paths     = ["lib"]

	s.test_file         = "tests/testem.rb"
	s.extensions        = "ext/extconf.rb"

	s.author            = "Francis Cianfrocca"
	s.email             = "garbagecat10@gmail.com"
	s.rubyforge_project = %q(eventmachine)
	s.homepage          = "http://rubyeventmachine.com"


	description = []
	File.open("README") do |file|
		file.each do |line|
			line.chomp!
			break if line.empty?
			description << "#{line.gsub(/\[\d\]/, '')}"
		end
	end
	s.description = description[1..-1].join(" ")
end

spec.version = $version
desc "Build the EventMachine RubyGem"
task :gem => ["pkg/eventmachine-#{$version}.gem"]
Rake::GemPackageTask.new(spec) do |g|
  if $can_minitar
    g.need_tar    = false
    g.need_zip    = false
  end
  g.package_dir = "pkg"
end


jspec = Gem::Specification.new do |s|
	s.name              = "eventmachine-java"
	s.summary           = "Ruby/EventMachine library"
	s.platform          = Gem::Platform::RUBY

	s.has_rdoc          = true
	s.rdoc_options      = %w(--title EventMachine --main README --line-numbers)
	s.extra_rdoc_files = ["README", "RELEASE_NOTES", "COPYING", "GNU", "LEGAL", "TODO"]

	s.files             = FileList["{lib}/**/*"].exclude("rdoc").to_a

	s.require_paths     = ["lib"]

	s.author            = "Francis Cianfrocca"
	s.email             = "garbagecat10@gmail.com"
	s.rubyforge_project = %q(eventmachine)
	s.homepage          = "http://rubyeventmachine.com"


	description = []
	File.open("README") do |file|
		file.each do |line|
			line.chomp!
			break if line.empty?
			description << "#{line.gsub(/\[\d\]/, '')}"
		end
	end
	s.description = description[1..-1].join(" ")
end


jspec.version = $version
desc "Build the EventMachine RubyGem for JRuby"
task :jgem => ["pkg/eventmachine-java-#{$version}.gem"]
Rake::GemPackageTask.new(jspec) do |g|
	$>.puts "-----------------"
	$>.puts "Before executing the :jgem task, be sure to run :clean, and"
	$>.puts "then make sure an up-to-date em_reactor.jar is present in the"
	$>.puts "lib directory."
	$>.puts "-----------------"
  if $can_minitar
    g.need_tar    = false
    g.need_zip    = false
  end
  g.package_dir = "pkg"
end


desc "Clean extension and JAR builds out of the lib directory"
task :clean do |t|
	files = %W(lib/*.so lib/*.jar)
        files = FileList[files.map { |file| File.join(".", file) }].to_a
	files.each {|f|
		$>.puts "unlinking file: #{f}"
		File.unlink f
	}
end


if $can_minitar
  desc "Build #$name .tar.gz distribution."
  task :tar => [ $tardist ]
  file $tardist => [ ] do |t|
    current = File.basename(Dir.pwd)
    Dir.chdir("..") do
      begin
        files = %W(ext/**/*.rb ext/**/*.cpp ext/**/*.h bin/**/* lib/**/* tests/**/* README COPYING
                 GNU LEGAL RELEASE_NOTES INSTALL EPOLL TODO KEYBOARD 
		LIGHTWEIGHT_CONCURRENCY PURE_RUBY SMTP SPAWNED_PROCESSES DEFERRABLES setup.rb )
        files = FileList[files.map { |file| File.join(current, file) }].to_a
	files = files.select {|f| f !~ /lib\/.*[\.](so|jar)\Z/i } # remove any so or jar files in the lib directory
        files.map! do |dd|
          ddnew = dd.gsub(/^#{current}/, $distdir)
          mtime = $release_date || File.stat(dd).mtime
          if File.directory?(dd)
            { :name => ddnew, :mode => 0755, :dir => true, :mtime => mtime }
          else
            if dd =~ %r{bin/}
              mode = 0755
            else
              mode = 0644
            end
            data = File.open(dd, "rb") { |ff| ff.read }
            { :name => ddnew, :mode => mode, :data => data, :size =>
              data.size, :mtime => mtime }
          end
        end

        ff = File.open(t.name.gsub(%r{^\.\./}o, ''), "wb")
        gz = Zlib::GzipWriter.new(ff)
        tw = Archive::Tar::Minitar::Writer.new(gz)

        files.each do |entry|
          if entry[:dir]
            tw.mkdir(entry[:name], entry)
          else
            tw.add_file_simple(entry[:name], entry) { |os| os.write(entry[:data]) }
          end
        end
      ensure
        tw.close if tw
        gz.finish if gz
        ff.close if ff
      end
    end
  end
  task $tardist => [ ]
end





# This is used by several rake tasks, that parameterize the
# behavior so we can use the same tests to test both the
# extension and non-extension versions.
def run_tests t, libr, test_filename_filter="test_*.rb"
  require 'test/unit/testsuite'
  require 'test/unit/ui/console/testrunner'

  runner = Test::Unit::UI::Console::TestRunner

  $eventmachine_library = ((RUBY_PLATFORM =~ /java/) ? :java : libr)
  $LOAD_PATH.unshift('tests')
  $stderr.puts "Checking for test cases:" #if t.verbose

  if test_filename_filter.is_a?(Array)
    test_filename_filter.each {|testcase|
      $stderr.puts "\t#{testcase}"
      load "tests/#{testcase}"
    }
  else
    Dir["tests/#{test_filename_filter}"].each do |testcase|
      $stderr.puts "\t#{testcase}" #if t.verbose
      load testcase
    end
  end

  suite = Test::Unit::TestSuite.new($name)

  ObjectSpace.each_object(Class) do |testcase|
    suite << testcase.suite if testcase < Test::Unit::TestCase
  end

  runner.run(suite)
end

desc "Run tests for #$name."
task :test do |t|
  run_tests t, nil
end

desc "Run tests for #$name."
task :test_partial do |t|
  run_tests t, :extension, [
    "test_basic.rb",
    "test_epoll.rb",
    "test_errors.rb",
    "test_eventables.rb",
    "test_exc.rb",
    "test_futures.rb",
    "test_hc.rb",
    "test_httpclient2.rb",
    "test_httpclient.rb",
    "test_kb.rb",
    #"test_ltp2.rb",
    "test_ltp.rb",
    "test_next_tick.rb",
    "test_processes.rb",
    "test_pure.rb",
    "test_running.rb",
    "test_sasl.rb",
    #"test_send_file.rb",
    "test_servers.rb",
    "test_smtpclient.rb",
    "test_smtpserver.rb",
    "test_spawn.rb",
    "test_timers.rb",
    "test_ud.rb",
  ]
end


desc "Run pure-ruby tests for #$name."
task :testpr do |t|
  run_tests t, :pure_ruby
end

desc "Run extension tests for #$name."
task :testext do |t|
  run_tests t, :extension
end

desc "PROVISIONAL: run tests for user-defined events"
task :test_ud do |t|
  run_tests t, :extension, "test_ud.rb"
end

desc "PROVISIONAL: run tests for line/text protocol handler"
task :test_ltp do |t|
  run_tests t, :extension, "test_ltp*.rb"
end

desc "PROVISIONAL: run tests for header/content protocol handler"
task :test_hc do |t|
  run_tests t, :extension, "test_hc.rb"
end

desc "PROVISIONAL: run tests for exceptions"
task :test_exc do |t|
  run_tests t, :extension, "test_exc.rb"
end

desc "Test protocol handlers"
task :test_protocols => [ :test_hc, :test_ltp ]


desc "Test HTTP client"
task :test_httpclient do |t|
  run_tests t, :extension, "test_httpclient.rb"
end

desc "Test HTTP client2"
task :test_httpclient2 do |t|
  run_tests t, :extension, "test_httpclient2.rb"
end

desc "Test futures"
task :test_futures do |t|
  run_tests t, :extension, "test_future*.rb"
end

desc "Test Timers"
task :test_timers do |t|
  run_tests t, :extension, "test_timer*.rb"
end

desc "Test Next Tick"
task :test_next_tick do |t|
  run_tests t, :extension, "test_next_tick*.rb"
end

desc "Test Epoll"
task :test_epoll do |t|
  run_tests t, :extension, "test_epoll*.rb"
end

desc "Test Servers"
task :test_servers do |t|
  run_tests t, :extension, "test_servers*.rb"
end

desc "Test Basic"
task :test_basic do |t|
  run_tests t, :extension, "test_basic*.rb"
end

desc "Test Send File"
task :test_send_file do |t|
  run_tests t, :extension, "test_send_file*.rb"
end

desc "Test Running"
task :test_running do |t|
  run_tests t, :extension, "test_running*.rb"
end

desc "Test Keyboard Events"
task :test_keyboard do |t|
  run_tests t, :extension, "test_kb*.rb"
end

desc "Test Spawn"
task :test_spawn do |t|
  run_tests t, :spawn, "test_spawn*.rb"
end

desc "Test SMTP"
task :test_smtp do |t|
  run_tests t, :extension, "test_smtp*.rb"
end

desc "Test Errors"
task :test_errors do |t|
  run_tests t, :extension, "test_errors*.rb"
end

desc "Test Pure Ruby"
task :test_pure do |t|
  run_tests t, :extension, "test_pure*.rb"
end

desc "Test Processes"
task :test_processes do |t|
  run_tests t, :extension, "test_process*.rb"
end

desc "Test SASL"
task :test_sasl do |t|
  run_tests t, :extension, "test_sasl*.rb"
end

desc "Test Attach"
task :test_attach do |t|
  run_tests t, :extension, "test_attach*.rb"
end


desc "Build everything"
task :default => [ :gem ]



# This task is useful for development.
desc "Compile the extension."
task :extension do |t|
	Dir.mkdir "nonversioned" unless File.directory?("nonversioned")
	Dir.chdir "nonversioned"
	system "ruby ../ext/extconf.rb"
	system "make clean"
	system "make"
	system "cp *.so ../lib" or system "copy *.so ../lib"
	Dir.chdir ".."
end


# This task creates the JRuby JAR file and leaves it in the lib directory.
# This step is required before executing the jgem task.
desc "Compile the JAR"
task :jar do |t|
	p "JAR?"
end

