require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.pattern = 'tests/**/test_*.rb'
  t.warning = true
end
