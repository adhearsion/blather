# $Id: tc_node_xlink.rb 481 2008-07-19 08:59:39Z cfis $
require "xml"
require 'test/unit'

class TC_XML_Node_XLink < Test::Unit::TestCase
  def setup()
    xp = XML::Parser.new()
    str = '<ruby_array xmlns:xlink="http://www.w3.org/1999/xlink/namespace/"><fixnum xlink:type="simple">one</fixnum></ruby_array>'
    assert_equal(str, xp.string = str)
    doc = xp.parse
    assert_instance_of(XML::Document, doc)
    @root = doc.root
    assert_instance_of(XML::Node, @root)
  end

  def teardown()
    @root = nil
  end

  def test_xml_node_xlink()
    for elem in @root.find('fixnum')
      assert_instance_of(XML::Node, elem)
      assert_instance_of(TrueClass, elem.xlink?)
      assert_equal("simple", elem.xlink_type_name)
      assert_equal(XML::Node::XLINK_TYPE_SIMPLE, elem.xlink_type)
    end
  end
end
