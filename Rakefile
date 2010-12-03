require 'rubygems' unless defined?(Gem)
require 'rake'     unless defined?(Rake)
import  *Dir['tasks/*.rake']

GEMSPEC = eval(File.read(File.expand_path('../eventmachine.gemspec', __FILE__)))

require 'rake/clean'
task :clobber => :clean

desc "Build eventmachine, then run tests."
task :default => [:compile, :test]
