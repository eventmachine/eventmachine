source 'https://rubygems.org'

gemspec

gem 'rake'

install_if -> { RUBY_VERSION > '3.1' } do
  gem "net-smtp"
end

group :documentation do
  gem 'yard', '>= 0.8.5.2'
  gem 'redcarpet' unless RUBY_PLATFORM =~ /java|mswin/
end
