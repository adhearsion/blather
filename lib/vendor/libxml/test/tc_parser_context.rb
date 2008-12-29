require "xml"
require 'test/unit'

class TestParserContext < Test::Unit::TestCase
  def setup
    str = '<ruby_array uga="booga" foo="bar"><fixnum>one</fixnum><fixnum>two</fixnum></ruby_array>'
    xp = XML::Parser.string(str)
    assert_equal(str, xp.string = str)
    doc = xp.parse
    assert_instance_of(XML::Document, doc)
    @ctxt = xp.context
    assert_instance_of(XML::Parser::Context, @ctxt)
  end

  def teardown
    @ctxt = nil
  end

  def test_well_formed
    if @ctxt.well_formed?
      assert_instance_of(TrueClass, @ctxt.well_formed?)
    else
      assert_instance_of(FalseClass, @ctxt.well_formed?)
    end
  end

  def test_version_info
    assert_instance_of(String, @ctxt.version)
  end

  def test_depth
    assert_instance_of(Fixnum, @ctxt.depth)
  end

  def test_disable_sax
    assert(!@ctxt.disable_sax?)
  end

  def test_docbook
    assert(!@ctxt.docbook?)
  end

  def test_encoding
    assert(!@ctxt.encoding)
  end

  def test_html
    assert(!@ctxt.html?)
  end

  def test_keep_blanks
    if @ctxt.keep_blanks?
      assert_instance_of(TrueClass, @ctxt.keep_blanks?)
    else
      assert_instance_of(FalseClass, @ctxt.keep_blanks?)
    end
  end

  if ENV['NOTWORKING']
    def test_num_chars
      assert_equal(17, @ctxt.num_chars)
    end
  end

  def test_replace_entities
    if @ctxt.replace_entities?
      assert_instance_of(TrueClass, @ctxt.replace_entities?)
    else
      assert_instance_of(FalseClass, @ctxt.replace_entities?)
    end
  end

  def test_space_depth
    assert_equal(1, @ctxt.space_depth)
  end

  def test_subset_external
    assert(!@ctxt.subset_external?)
  end

  def test_data_directory_get
    assert_nil(@ctxt.data_directory)
  end

  def test_parse_error
    xp = XML::Parser.new
    xp.string = '<foo><bar/></foz>'
    
    assert_raise(XML::Error) do
      xp.parse
    end
    
    # Now check context
    context = xp.context
    assert_equal(nil, context.data_directory)
    assert_equal(0, context.depth)
    assert_equal(true, context.disable_sax?)
    assert_equal(false, context.docbook?)
    assert_equal(nil, context.encoding)
    assert_equal(76, context.errno)
    assert_equal(false, context.html?)
    assert_equal(5, context.io_max_num_streams)
    assert_equal(1, context.io_num_streams)
    assert_equal(true, context.keep_blanks?)
    assert_equal(1, context.io_num_streams)
    assert_equal(nil, context.name_node)
    assert_equal(0, context.name_depth)
    assert_equal(10, context.name_depth_max)
    assert_equal(17, context.num_chars)
    assert_equal(true, context.replace_entities?)
    assert_equal(1, context.space_depth)
    assert_equal(10, context.space_depth_max)
    assert_equal(false, context.subset_external?)
    assert_equal(nil, context.subset_external_system_id)
    assert_equal(nil, context.subset_external_uri)
    assert_equal(false, context.subset_internal?)
    assert_equal(nil, context.subset_internal_name)
    assert_equal(false, context.stats?)
    assert_equal(true, context.standalone?)
    assert_equal(false, context.valid)
    assert_equal(false, context.validate?)
    assert_equal('1.0', context.version)
    assert_equal(false, context.well_formed?)
  end
end
