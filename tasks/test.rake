require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "tests"
  t.pattern = 'tests/**/test_*.rb'
  t.warning = true
end
