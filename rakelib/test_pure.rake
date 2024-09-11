require 'rake/testtask'

task :test_em_pure_ruby do
  ENV['EM_PURE_RUBY'] = 'true'
  Rake::Task['test'].execute
end

task test_em_pure_ruby: "test:fixtures"
