def declare_gems
  
  source :rubygems
  
  gem 'rake'
  gem 'eventmachine'
  gem 'active_support'
  gem 'mocha'
  gem 'minitest', '~> 1.7.1'
  gem 'jruby-openssl', '~> 0.7.4' if RUBY_PLATFORM =~ /java/

  # gem 'niceogiri', '0.1.0'
  # use a fork without constraints on Nokogiri version
  gem "niceogiri", :git => "git://github.com/thbar/niceogiri.git", :ref => '787f4e07'
  
  yield

end