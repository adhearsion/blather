require "xml"
require 'test/unit'


class TestDocument < Test::Unit::TestCase
  def setup
    xp = XML::Parser.new
    assert_instance_of(XML::Parser, xp)
    str = '<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>'
    assert_equal(str, xp.string = str)
    @doc = xp.parse
    assert_instance_of(XML::Document, @doc)
  end

  def teardown
    @doc = nil
  end

  def test_klass
    assert_instance_of(XML::Document, @doc)
  end

  def test_context
    context = @doc.context
    assert_instance_of(XML::XPath::Context, context)
  end

  def test_find
    set = @doc.find('/ruby_array/fixnum')
    assert_instance_of(XML::XPath::Object, set)
    assert_raise(NoMethodError) {
      xpt = set.xpath
    }
  end

  def test_ruby_xml_document_compression
    if XML.enabled_zlib?
      0.upto(9) do |i|
        assert_equal(i, @doc.compression = i)
        assert_equal(i, @doc.compression)
      end

      9.downto(0) do |i|
        assert_equal(i, @doc.compression = i)
        assert_equal(i, @doc.compression)
      end

      10.upto(20) do |i|
        # assert_equal(9, @doc.compression = i)
        assert_equal(i, @doc.compression = i) # This works around a bug in Ruby 1.8
        assert_equal(9, @doc.compression)
      end

      -1.downto(-10) do |i|
        # assert_equal(0, @doc.compression = i)
        assert_equal(i, @doc.compression = i) # FIXME This bug should get fixed ASAP
        assert_equal(0, @doc.compression)
      end
    end
  end

  def test_version
    assert_equal('1.0', @doc.version)

    doc = XML::Document.new('6.9')
    assert_equal('6.9', doc.version)
  end

  def test_write_root
    @doc.root = XML::Node.new('rubynet')
    assert_instance_of(XML::Node, @doc.root)
    assert_instance_of(XML::Document, @doc.root.doc)
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rubynet/>\n",
                 @doc.to_s(:indent => false))
  end
end
