require "xml"
require 'test/unit'

class TestDtd < Test::Unit::TestCase
  def setup
    xp = XML::Parser.string(<<-EOS)
      <root>
        <head a="ee" id="1">Colorado</head>
        <descr>Lots of nice mountains</descr>
      </root>
    EOS
    @doc = xp.parse
  end
  
  def teardown
    @doc = nil
  end
  
  def dtd
    XML::Dtd.new(<<-EOS)
      <!ELEMENT root (head, descr)>
      <!ELEMENT head (#PCDATA)>
      <!ATTLIST head
        id NMTOKEN #REQUIRED
        a CDATA #IMPLIED
      >
      <!ELEMENT descr (#PCDATA)>
    EOS
  end
  
  def test_valid
    assert(@doc.validate(dtd))
  end

  def test_invalid
    new_node = XML::Node.new('invalid', 'this will mess up validation')
    @doc.root.child_add(new_node)

    messages = Hash.new
    error = assert_raise(XML::Error) do
      @doc.validate(dtd)
    end

    # Check the error worked
    assert_not_nil(error)
    assert_kind_of(XML::Error, error)
    assert_equal("Error: No declaration for element invalid at :0.", error.message)
    assert_equal(XML::Error::VALID, error.domain)
    assert_equal(XML::Error::DTD_UNKNOWN_ELEM, error.code)
    assert_equal(XML::Error::ERROR, error.level)
    assert_nil(error.file)
    assert_nil(error.line)
    assert_equal('invalid', error.str1)
    assert_equal('invalid', error.str2)
    assert_nil(error.str3)
    assert_equal(0, error.int1)
    assert_equal(0, error.int2)
    assert_not_nil(error.node)
    assert_equal('invalid', error.node.name)
  end
  
  def test_external_dtd
    xml = <<-EOS
      <!DOCTYPE test PUBLIC "-//TEST" "test.dtd" []>
      <test>
        <title>T1</title>
      </test>
    EOS

    errors = Array.new
    XML::Error.set_handler do |error|
      errors << error
    end

    XML.default_load_external_dtd = false
    doc = XML::Parser.string(xml).parse
    assert_equal(Array.new, errors)

    XML.default_load_external_dtd = true
    doc = XML::Parser.string(xml).parse
    assert_equal("Warning: failed to load external entity \"test.dtd\" at :1.",
                  errors.map do |error|
                    error.to_s
                  end.join(' '))
  end
end