require 'xml'
require 'test/unit'
require 'stringio'

class TestParser < Test::Unit::TestCase
  def setup
    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    @xp = XML::Parser.new
  end

  def teardown
    @xp = nil
    GC.start
    GC.start
    GC.start
  end
      
  # -----  Sources  ------
  def test_file
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))

    @xp.file = file
    assert_equal(file, @xp.file)
    assert_equal(file, @xp.input.file)

    doc = @xp.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, @xp.context)
    GC.start
    GC.start
    GC.start
 end

  def test_file_class
    file = File.expand_path(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))

    xp = XML::Parser.file(file)
    assert_instance_of(XML::Parser, xp)
    assert_equal(file, xp.file)
    assert_equal(file, xp.input.file)
  end

  def test_string
    str = '<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>'

    @xp.string = str
    assert_equal(str, @xp.string)
    assert_equal(str, @xp.input.string)

    doc = @xp.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, @xp.context)
  end

  def test_string_empty
    assert_raise(XML::Error) do
      @xp.string = ''
      @xp.parse
    end

    assert_raise(TypeError) do
      @xp.string = nil
    end
  end

  def test_string_class
    str = '<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>'

    xp = XML::Parser.string(str)
    assert_instance_of(XML::Parser, xp)
    assert_equal(str, xp.string)
    assert_equal(str, xp.input.string)
  end

  def test_io
    File.open(File.join(File.dirname(__FILE__), 'model/rubynet.xml')) do |io|
      @xp.io = io
      assert_equal(io, @xp.io)
      assert_equal(io, @xp.input.io)

      doc = @xp.parse
      assert_instance_of(XML::Document, doc)
      assert_instance_of(XML::Parser::Context, @xp.context)
    end
  end

  def test_io_class
    File.open(File.join(File.dirname(__FILE__), 'model/rubynet.xml')) do |io|
      xp = XML::Parser.io(io)
      assert_instance_of(XML::Parser, xp)
      assert_equal(io, xp.io)
      assert_equal(io, xp.input.io)

      doc = xp.parse
      assert_instance_of(XML::Document, doc)
      assert_instance_of(XML::Parser::Context, xp.context)
    end
  end

  def test_string_io
    data = File.read(File.join(File.dirname(__FILE__), 'model/rubynet.xml'))
    string_io = StringIO.new(data)
    @xp.io = string_io
    assert_equal(string_io, @xp.io)
    assert_equal(string_io, @xp.input.io)

    doc = @xp.parse
    assert_instance_of(XML::Document, doc)
    assert_instance_of(XML::Parser::Context, @xp.context)
  end

  def test_fd_gc
    # Test opening # of documents up to the file limit for the OS.
    # Ideally it should run until libxml emits a warning,
    # thereby knowing we've done a GC sweep. For the time being,
    # re-open the same doc `limit descriptors` times.
    # If we make it to the end, then we've succeeded,
    # otherwise an exception will be thrown.
    XML::Error.set_handler {|error|}

    max_fd = if RUBY_PLATFORM.match(/mswin32/i)
      500
    else
      (`ulimit -n`.chomp.to_i) + 1
    end

    file = File.join(File.dirname(__FILE__), 'model/rubynet.xml')
    max_fd.times do
       XML::Parser.file(file).parse
    end
    XML::Error.reset_handler {|error|}
  end


  # -----  Errors  ------
  def test_error
    error = assert_raise(XML::Error) do
      XML::Parser.string('<foo><bar/></foz>').parse
    end

    assert_not_nil(error)
    assert_kind_of(XML::Error, error)
    assert_equal("Fatal error: Opening and ending tag mismatch: foo line 1 and foz at :1.", error.message)
    assert_equal(XML::Error::PARSER, error.domain)
    assert_equal(XML::Error::TAG_NAME_MISMATCH, error.code)
    assert_equal(XML::Error::FATAL, error.level)
    assert_nil(error.file)
    assert_equal(1, error.line)
    assert_equal('foo', error.str1)
    assert_equal('foz', error.str2)
    assert_nil(error.str3)
    assert_equal(1, error.int1)
    assert_equal(20, error.int2)
    assert_nil(error.node)
  end

  def test_bad_xml
    @xp.string = '<ruby_array uga="booga" foo="bar"<fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>'
    error = assert_raise(XML::Error) do
      assert_not_nil(@xp.parse)
    end

    assert_not_nil(error)
    assert_kind_of(XML::Error, error)
    assert_equal("Fatal error: Extra content at the end of the document at :1.", error.message)
    assert_equal(XML::Error::PARSER, error.domain)
    assert_equal(XML::Error::DOCUMENT_END, error.code)
    assert_equal(XML::Error::FATAL, error.level)
    assert_nil(error.file)
    assert_equal(1, error.line)
    assert_nil(error.str1)
    assert_nil(error.str2)
    assert_nil(error.str3)
    assert_equal(0, error.int1)
    assert_equal(20, error.int2)
    assert_nil(error.node)
  end

  def test_double_parse
    parser = XML::Parser.string("<test>something</test>")
    doc = parser.parse

    assert_raise(RuntimeError) do
      parser.parse
    end
  end
end