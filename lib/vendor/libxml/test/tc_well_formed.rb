require 'xml'
require 'test/unit'

class TestWellFormed < Test::Unit::TestCase
  def test_xml_node_doc_get()
    parser = XML::Parser.new
    parser.string = "<p>I am well formed</p>"
    parser.parse
    assert(parser.context.well_formed?)
  end
end