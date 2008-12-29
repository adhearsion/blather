require "xml"
require 'test/unit'

class HtmlParserTest < Test::Unit::TestCase
  def setup
    @xp = XML::HTMLParser.new()
    assert_not_nil(@xp)
    str = '<html><head><meta name=keywords content=nasty></head><body>Hello<br>World</html>'
    @xp.string = str
    assert_equal(str, @xp.string)
  end

  def teardown()
    @xp = nil
  end

  def html_file
    File.expand_path(File.join(File.dirname(__FILE__), 'model/ruby-lang.html'))
  end

  # -----  Sources  ------
  def test_file
    xp = XML::HTMLParser.file(html_file)
    assert_instance_of(XML::HTMLParser, xp)
    assert_equal(html_file, xp.file)
    assert_equal(html_file, xp.input.file)
  end

  def test_string
    str = '<html><body><p>hi</p></body></html>'
    xp = XML::HTMLParser.string(str)

    assert_instance_of(XML::HTMLParser, xp)
    assert_instance_of(XML::HTMLParser, xp)
    assert_equal(str, xp.string)
    assert_equal(str, xp.input.string)

    doc = xp.parse
    assert_instance_of(XML::Document, doc)
  end

  def test_io
    File.open(html_file) do |io|
      xp = XML::HTMLParser.io(io)
      assert_instance_of(XML::HTMLParser, xp)
      assert_equal(io, xp.io)
      assert_equal(io, xp.input.io)

      doc = xp.parse
      assert_instance_of(XML::Document, doc)
    end
  end

  def test_string_io
    data = File.read(html_file)
    io = StringIO.new(data)
    xp = XML::HTMLParser.io(io)
    assert_instance_of(XML::HTMLParser, xp)
    assert_equal(io, xp.io)
    assert_equal(io, xp.input.io)

    doc = xp.parse
    assert_instance_of(XML::Document, doc)
  end

  def test_libxml_html_parser_parse
    doc = @xp.parse

    assert_instance_of XML::Document, doc

    root = doc.root
    assert_instance_of XML::Node, root
    assert_equal 'html', root.name

    head = root.child
    assert_instance_of XML::Node, head
    assert_equal 'head', head.name

    meta = head.child
    assert_instance_of XML::Node, meta
    assert_equal 'meta', meta.name
    assert_equal 'keywords', meta[:name]
    assert_equal 'nasty', meta[:content]

    body = head.next
    assert_instance_of XML::Node, body
    assert_equal 'body', body.name

    hello = body.child
    # It appears that some versions of libxml2 add a layer of <p>
    # cant figure our why or how, so this skips it if there
    hello = hello.child if hello.name == "p"

    assert_instance_of XML::Node, hello
    assert_equal 'Hello', hello.content

    br = hello.next
    assert_instance_of XML::Node, br
    assert_equal 'br', br.name

    world = br.next
    assert_instance_of XML::Node, world
    assert_equal 'World', world.content
  end
end