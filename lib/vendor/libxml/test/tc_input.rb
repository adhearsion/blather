require 'xml'
require 'test/unit'

class TestInput < Test::Unit::TestCase
  def test_latin1
    assert_equal(XML::Input::ISO_8859_1, 10)
  end

  def test_latin1_to_s
    encoding_str = XML::Input.encoding_to_s(XML::Input::ISO_8859_1)
    assert_equal('ISO-8859-1', encoding_str)
  end
end
