source "http://rubygems.org"

# Specify your gem's dependencies in testgem.gemspec
gemspec

if RUBY_PLATFORM =~ /darwin/
  gem 'growl_notify'
  gem 'rb-fsevent'
end

gem 'bluecloth' unless RUBY_PLATFORM =~ /java/
