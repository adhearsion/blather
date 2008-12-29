require 'xml'
require 'test/unit'

class TestReader < Test::Unit::TestCase

  SIMPLE_XML = File.join(File.dirname(__FILE__), 'model/simple.xml')

  def verify_simple(reader)
    node_types = []
    19.times do
      assert_equal(1, reader.read)
      node_types << reader.node_type
    end
    assert_equal(0, reader.read)
    assert_equal(node_types,
      [XML::Reader::TYPE_ELEMENT,
       XML::Reader::TYPE_SIGNIFICANT_WHITESPACE,
       XML::Reader::TYPE_ELEMENT,
       XML::Reader::TYPE_TEXT,
       XML::Reader::TYPE_END_ELEMENT,
       XML::Reader::TYPE_SIGNIFICANT_WHITESPACE,
       XML::Reader::TYPE_ELEMENT,
       XML::Reader::TYPE_SIGNIFICANT_WHITESPACE,
       XML::Reader::TYPE_ELEMENT,
       XML::Reader::TYPE_TEXT,
       XML::Reader::TYPE_END_ELEMENT,
       XML::Reader::TYPE_SIGNIFICANT_WHITESPACE,
       XML::Reader::TYPE_ELEMENT,
       XML::Reader::TYPE_TEXT,
       XML::Reader::TYPE_END_ELEMENT,
       XML::Reader::TYPE_SIGNIFICANT_WHITESPACE,
       XML::Reader::TYPE_END_ELEMENT,
       XML::Reader::TYPE_SIGNIFICANT_WHITESPACE,
       XML::Reader::TYPE_END_ELEMENT])
  end

  def test_file
    reader = XML::Reader.file(SIMPLE_XML)
    verify_simple(reader)
  end

  def test_invalid_file
    assert_raises(XML::Error) do
      XML::Reader.file('/does/not/exist')
    end
  end

  def test_string
    reader = XML::Reader.string(File.read(SIMPLE_XML))
    verify_simple(reader)
  end

  def test_io
    File.open(SIMPLE_XML, 'rb') do |io|
      reader = XML::Reader.io(io)
      verify_simple(reader)
    end
  end

  def test_string_io
    data = File.read(SIMPLE_XML)
    string_io = StringIO.new(data)
    reader = XML::Reader.io(string_io)
    verify_simple(reader)
  end

  def test_new_walker
    reader = XML::Reader.walker(XML::Document.file(SIMPLE_XML))
    verify_simple(reader)
  end

  def test_deprecated_error_handler
    called = false
    reader = XML::Reader.new('<foo blah')
    reader.set_error_handler do |error|
      called = true
    end

    reader.read
    assert(called)
  end

  def test_deprecated_reset_error_handler
    called = false
    reader = XML::Reader.new('<foo blah')
    reader.set_error_handler do |error|
      called = true
    end
    reader.reset_error_handler

    reader.read
    assert(!called)
  end

  def test_attr
    parser = XML::Reader.new("<foo x='1' y='2'/>")
    assert_equal(1, parser.read)
    assert_equal('foo', parser.name)
    assert_equal('1', parser['x'])
    assert_equal('1', parser[0])
    assert_equal('2', parser['y'])
    assert_equal('2', parser[1])
    assert_equal(nil, parser['z'])
    assert_equal(nil, parser[2])
  end

  def test_value
    parser = XML::Reader.new("<foo><bar>1</bar><bar>2</bar><bar>3</bar></foo>")
    assert_equal(1, parser.read)
    assert_equal('foo', parser.name)
    assert_equal(nil, parser.value)
    3.times do |i|
      assert_equal(1, parser.read)
      assert_equal(XML::Reader::TYPE_ELEMENT, parser.node_type)
      assert_equal('bar', parser.name)
      assert_equal(1, parser.read)
      assert_equal(XML::Reader::TYPE_TEXT, parser.node_type)
      assert_equal((i + 1).to_s, parser.value)
      assert_equal(1, parser.read)
      assert_equal(XML::Reader::TYPE_END_ELEMENT, parser.node_type)
    end
  end

  def test_expand
    reader = XML::Reader.file(SIMPLE_XML)
    reader.read
    node = reader.expand
    doc = node.doc
    reader.close
    GC.start

    doc.standalone?
  end

  def test_mode
    reader = XML::Reader.string('<xml/>')
    assert_equal(XML::Reader::MODE_INITIAL, reader.read_state)
    reader.read
    assert_equal(XML::Reader::MODE_EOF, reader.read_state)
  end
end