source 'https://rubygems.org'

gemspec

gem 'rake'

install_if -> { RUBY_VERSION > '3.1' } do
  gem 'net-smtp'
end

# switch to install_if when ruby 2.2 support is dropped
if RUBY_VERSION >= '3.0'
  gem 'sorted_set'
end

group :documentation do
  gem 'yard', '>= 0.8.5.2'
  gem 'redcarpet' unless RUBY_PLATFORM =~ /java|mswin/
end
