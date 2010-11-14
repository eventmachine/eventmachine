#!/usr/bin/env rake
#
# Ruby/EventMachine
#   http://rubyeventmachine.com
#   Copyright (C) 2006-07 by Francis Cianfrocca
#
#   This program is copyrighted free software. You may use it under
#   the terms of either the GPL or Ruby's License. See the file
#   COPYING in the EventMachine distribution for full licensing
#   information.
#

require 'rubygems'  unless defined?(Gem)
require 'rake'      unless defined?(Rake)

Package = false # Build zips and tarballs?
Dir.glob('tasks/*.rake').each { |r| Rake.application.add_import r }

MAKE = ENV['MAKE'] || if RUBY_PLATFORM =~ /mswin/ # mingw uses make.
  'nmake'
else
  'make'
end

desc "Build gemspec, then build eventmachine, then run tests."
task :default => [:build, :test]

desc "Build extension (or EVENTMACHINE_LIBRARY) and place in lib"
build_task = 'ext:build'
build_task = 'java:build' if RUBY_PLATFORM =~ /java/
task :build => build_task do |t|
  Dir.glob('{ext,java/src,ext/fastfilereader}/*.{so,bundle,dll,jar}').each do |f|
    mv f, "lib"
  end
end

task :dummy_build

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'tests/**/test_*.rb'
  t.warning = true
end

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

Spec = eval(File.read(File.expand_path('../eventmachine.gemspec', __FILE__)))

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
  file ext_extconf = 'ext/extconf.rb'
  file ffr_extconf = 'ext/fastfilereader/extconf.rb'
  ext_libname = "lib/rubyeventmachine.#{Config::CONFIG['DLEXT']}"
  ffr_libname = "lib/fastfilereaderext.#{Config::CONFIG['DLEXT']}"

  file ext_libname => ext_sources + ['ext/Makefile'] do
    chdir('ext') { sh MAKE }
  end
  
  file ffr_libname => ffr_sources + ['ext/fastfilereader/Makefile'] do
    chdir('ext/fastfilereader') { sh MAKE }
  end

  desc "Build C++ extension"
  task :build => [:make]

  task :make => ext_libname
  task :make => ffr_libname

  file 'ext/Makefile' => ext_extconf do
    chdir 'ext' do
      ruby 'extconf.rb'
    end
  end

  file 'ext/fastfilereader/Makefile' => ffr_extconf do
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
    mv 'java/em_reactor.jar', 'lib/'
  end

  task :compile do
    chdir('java') do
      mkdir_p "build"
      sh 'javac src/com/rubyeventmachine/*.java -d build'
    end
  end

  task :jar => [:compile] do
    chdir('java/build') do
      sh "jar -cf ../em_reactor.jar com/rubyeventmachine/*.class"
    end
  end

  desc "build a java binary gem"
  task :gem => :build do
    Spec.platform = 'java'
    Spec.files += %w[ lib/em_reactor.jar ]
    Spec.extensions = nil

    Rake::Task['gem'].invoke
  end
end

namespace :osx do
  desc "Build OSX binary gem"
  task :gem do
    Spec.platform = RUBY_PLATFORM.sub(/darwin.+$/, 'darwin')
    Spec.files += %w[ lib/rubyeventmachine.bundle lib/fastfilereaderext.bundle ]
    Spec.extensions = nil

    Rake::Task['build'].invoke
    Rake::Task['gem'].invoke
  end

  # XXX gcc will still prefer the shared libssl on the system, so we need to hack the extconf
  # XXX to use the static library to make this actually work
  task :static_gem => [:build_openssl, :gem]

  task :build_openssl do
    mkdir_p 'build'
    chdir 'build' do
      unless File.exists?('openssl-0.9.8j')
        sh 'curl http://www.openssl.org/source/openssl-0.9.8j.tar.gz > openssl-0.9.8j.tar.gz'
        sh 'tar zxvf openssl-0.9.8j.tar.gz'
      end

      mkdir_p 'local'
      chdir 'openssl-0.9.8j' do
        local_dir = File.expand_path(File.join(File.dirname(__FILE__),'build','local'))
        sh "./config --prefix=#{local_dir}"
        sh 'make'
        sh 'make install'
      end

      chdir '../ext' do
        sh 'git clean -fd .'
      end

      mv 'local/include/openssl', '../ext/'
      mv 'local/lib/libssl.a', '../ext/'
      mv 'local/lib/libcrypto.a', '../ext/'
    end
  end
end

require 'rake/clean'

rdoc_task_type = begin
  require 'rdoc/task'
  RDoc::Task
rescue LoadError
  require 'rake/rdoctask'
  Rake::RDocTask
end
df = begin; require 'rdoc/rdoc'; require 'rdoc/generator/darkfish'; true; rescue LoadError; end
rdtask = rdoc_task_type.new do |rd|
  rd.title = Spec.name
  rd.rdoc_dir = 'rdoc'
  rd.main = "README"
  rd.rdoc_files.include("lib/**/*.rb", *Spec.extra_rdoc_files)
  rd.rdoc_files.exclude(*%w(lib/em/version lib/emva lib/evma/ lib/pr_eventmachine lib/jeventmachine))
  rd.template = 'darkfish' if df
end
Rake::Task[:clean].enhance [:clobber_rdoc]

desc 'Generate and open documentation'
task :docs => :rdoc do
  case RUBY_PLATFORM
  when /darwin/       ; sh 'open rdoc/index.html'
  when /mswin|mingw/  ; sh 'start rdoc\index.html'
  else 
    sh 'firefox rdoc/index.html'
  end
end

def windows?; RUBY_PLATFORM =~ /mswin|mingw/; end
def sudo(cmd)
  if windows? || (require 'etc'; Etc.getpwuid.uid == 0)
    sh cmd
  else
    sh "sudo #{cmd}"
  end
end
def gem_cmd(action, name, *args)
  rb = Gem.ruby rescue nil
  rb ||= (require 'rbconfig'; File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name']))
  sudo "#{rb} -r rubygems -e 'require %{rubygems/gem_runner}; Gem::GemRunner.new.run(%w{#{action} #{name} #{args.join(' ')}})'"
end

begin
  require 'rubygems/package_task'
  Gem::PackageTask
rescue LoadError
  require 'rake/gempackagetask'
  Rake::GemPackageTask
end.new(Spec) do |pkg|
  pkg.need_tar, pkg.need_tar_gz, pkg.need_zip = true, true, true if Package
  pkg.gem_spec = Spec
end

Rake::Task[:clean].enhance [:clobber_package]

namespace :gem do
  desc 'Install gem (and sudo if required)'
  task :install => :package do 
    gem_cmd(:install, "pkg/#{Spec.name}-#{Spec.version}.gem")
  end

  desc 'Uninstall gem (and sudo if required)'
  task :uninstall do
    gem_cmd(:uninstall, "#{Spec.name}", "-v=#{Spec.version}")
  end
end

task :clobber => :clean
task :test => :build
