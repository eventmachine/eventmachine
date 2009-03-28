require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/clean'

# monkey bitchin' for windows stuffs...
module FileUtils
  # If any of these methods ever clobber, try removing them.
  # Hopefully they'll do something semantically similar.
  abort "Err: #{__FILE__}:#{__LINE__} monkey patch windows? clobbers!" unless instance_methods.grep(/windows\?/).empty?
  abort "Err: #{__FILE__}:#{__LINE__} monkey patch sudo clobbers!" unless instance_methods.grep(/sudo/).empty?
  abort "Err: #{__FILE__}:#{__LINE__} monkey patch gem_cmd clobbers!" unless instance_methods.grep(/gem_cmd/).empty?
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
end


# Setup our packaging tasks, we're just jacking the builtins.
Rake::GemPackageTask.new(Spec) do |pkg|
  pkg.need_tar, pkg.need_tar_gz, pkg.need_zip = true, true, true if Package
  pkg.gem_spec = Spec
end
Rake::Task[:clean].enhance [:clobber_package]

# Only generate rdoc if the spec says so, again, jack the builtins.
if Spec.has_rdoc
  Rake::RDocTask.new do |rd|
    rd.title = Spec.name
    rd.rdoc_dir = 'rdoc'
    rd.main = "README"
    rd.rdoc_files.include("lib/**/*.rb", *Spec.extra_rdoc_files)
    rd.rdoc_files.exclude(*%w(lib/em/version lib/emva lib/evma/ lib/pr_eventmachine lib/jeventmachine))
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
end

if Spec.default_executable
  desc "Run #{Spec.default_executable}"
  task :run do ruby File.join(Spec.bindir, Spec.default_executable) end
end

require 'rubygems'

desc 'Install gem (and sudo if required)'
task :install => :package do 
  gem_cmd(:install, "pkg/#{Spec.name}-#{Spec.version}.gem")
end

desc 'Uninstall gem (and sudo if required)'
task :uninstall do
  gem_cmd(:uninstall, "#{Spec.name}", "-v=#{Spec.version}")
end

# Find an scm's store directory, if we do, make a task to commit to it only
# after running all the tests (successfully).
if scm = %w(git svn bzr hg).find { |d| File.directory? ".#{d}" }
  desc "Run tests then commit to #{scm}"
  task :commit => :test do sh "#{scm} commit" end
end