rdoc_task_type = begin
  require 'rdoc/task'
  RDoc::Task
rescue LoadError
  require 'rake/rdoctask'
  Rake::RDocTask
end

df = begin; require 'rdoc/rdoc'; require 'rdoc/generator/darkfish'; true; rescue LoadError; end

rdtask = rdoc_task_type.new do |rd|
  rd.title = GEMSPEC.name
  rd.rdoc_dir = 'rdoc'
  rd.main = "README"
  rd.rdoc_files.include("lib/**/*.rb", *GEMSPEC.extra_rdoc_files)
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
