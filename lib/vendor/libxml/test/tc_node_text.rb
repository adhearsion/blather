require 'xml'
require 'test/unit'

class TestTextNode < Test::Unit::TestCase
  def test_content
    node = XML::Node.new_text('testdata')
    assert_instance_of(XML::Node, node)
    assert_equal('testdata', node.content)
  end

  def test_invalid_content
    error = assert_raise(TypeError) do
      node = XML::Node.new_text(nil)
    end
    assert_equal('wrong argument type nil (expected String)', error.to_s)
  end
end