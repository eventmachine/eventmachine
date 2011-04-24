require 'rubygems' unless defined?(Gem)
require 'rake'     unless defined?(Rake)
import  *Dir['tasks/*.rake']

GEMSPEC = eval(File.read(File.expand_path('../eventmachine.gemspec', __FILE__)))

require 'yard'
require 'rake/clean'
task :clobber => :clean

desc "Build eventmachine, then run tests."
task :default => [:compile, :test]

desc 'Generate documentation'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'docs/*.md']
  t.options = ['--main', 'README.md', '--no-private']
  t.options = ['--exclude', 'lib/jeventmachine', '--exclude', 'lib/pr_eventmachine']
end
