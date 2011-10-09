source "http://rubygems.org"

# Specify your gem's dependencies in testgem.gemspec
gemspec

if RUBY_PLATFORM =~ /darwin/ && (!defined?(RUBY_ENGINE) || RUBY_ENGINE != 'rbx')
  gem 'growl_notify'
  gem 'rb-fsevent'
end

unless (RUBY_PLATFORM =~ /java/ || (defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'))
  gem 'bluecloth'
end
