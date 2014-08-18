require 'blather'
require 'countdownlatch'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    GirlFriday::WorkQueue.immediate!
    Blather::Stream::Parser.debug = true
    Blather.logger = Logger.new($stdout).tap { |logger| logger.level = Logger::DEBUG }
  end
end

def parse_stanza(xml)
  Nokogiri::XML.parse xml
end

def jruby?
  RUBY_PLATFORM =~ /java/
end
