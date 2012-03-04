require 'blather'
require 'mocha'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

def parse_stanza(xml)
  Nokogiri::XML.parse xml
end
