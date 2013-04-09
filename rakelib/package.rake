require 'rubygems'
require 'rubygems/package_task'

begin
  require 'rake/extensiontask'
  require 'rake/javaextensiontask'
rescue LoadError => e
  puts <<-MSG
rake-compiler gem seems to be missing. Please install it with

  gem install rake-compiler

(add sudo if necessary).
  MSG
end

Gem::PackageTask.new(GEMSPEC) do |pkg|
end

if RUBY_PLATFORM =~ /java/
  Rake::JavaExtensionTask.new("rubyeventmachine", GEMSPEC) do |ext|
    ext.ext_dir = 'java/src'
  end
else
  def setup_cross_compilation(ext)
    unless RUBY_PLATFORM =~ /mswin|mingw/
      ext.cross_compile = true
      ext.cross_platform = ['x86-mingw32', 'x86-mswin32-60']
    end
  end
  def hack_cross_compilation(ext)
    # inject 1.8/1.9 pure-ruby entry point
    # HACK: add these dependencies to the task instead of using cross_compiling
    ext.cross_platform.each do |platform|
      task = "native:#{GEMSPEC.name}:#{platform}"
      if Rake::Task.task_defined?(task)
        Rake::Task[task].prerequisites.unshift "lib/#{ext.name}.rb"
      end
    end
  end

  em = Rake::ExtensionTask.new("rubyeventmachine", GEMSPEC) do |ext|
    ext.ext_dir = 'ext'
    ext.source_pattern = '*.{h,c,cpp}'
    setup_cross_compilation(ext)
  end
  hack_cross_compilation em

  ff = Rake::ExtensionTask.new("fastfilereaderext", GEMSPEC) do |ext|
    ext.ext_dir = 'ext/fastfilereader'
    ext.source_pattern = '*.{h,c,cpp}'
    setup_cross_compilation(ext)
  end
  hack_cross_compilation ff
end

# Setup shim files that require 1.8 vs 1.9 extensions in win32 bin gems
%w[ rubyeventmachine fastfilereaderext ].each do |filename|
  file("lib/#{filename}.rb") do |t|
    File.open(t.name, 'wb') do |f|
      f.write <<-eoruby
  RUBY_VERSION =~ /(\\d+.\\d+)/
  require "\#{$1}/#{File.basename(t.name, '.rb')}"
      eoruby
    end
    at_exit{ FileUtils.rm t.name if File.exists?(t.name) }
  end
end

task :cross_cxx do
  ENV['CROSS_COMPILING'] = 'yes'
  require 'rake/extensioncompiler'
  ENV['CXX'] = "#{Rake::ExtensionCompiler.mingw_host}-g++"
end

if Rake::Task.task_defined?(:cross)
  task :cross => 'lib/rubyeventmachine.rb'
  task :cross => 'lib/fastfilereaderext.rb'
  task :cross => :cross_cxx
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

Rake::Task[:clean].enhance [:clobber_package]
