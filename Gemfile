source 'https://rubygems.org'

gemspec

# Rake 11.0 no longer supports Ruby 1.8.7 and Ruby 1.9.2
if RUBY_VERSION <= '1.9.3'
  gem 'rake', '< 11.3'
else
  gem 'rake'
end

group :documentation do
  gem 'yard', '>= 0.8.5.2'
  gem 'redcarpet' unless RUBY_PLATFORM =~ /java|mswin/
end
