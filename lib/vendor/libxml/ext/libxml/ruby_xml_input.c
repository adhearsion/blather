/* $Id: rxml_input.c 528 2008-11-15 23:43:48Z cfis $ */

/* Please see the LICENSE file for copyright and distribution information */

#include <stdarg.h>
#include "ruby_libxml.h"

VALUE cXMLInput;

/*
 * Document-class: LibXML::XML::Input
 *
 * Input is a helper class that defines a libxml data source.
 * Libxml can parse files, strings, io streams and documents
 * accessible via networking protocols such as http.
 * Be default, the ruby-libxml bindings expose parsing
 * files, io streams and strings.
 *
 * Generally you will not directly work with the input object,
 * but instead will use the various Document and Parser apis.
 * For example:
 *
 *   parser = XML::Parser.file('my_file')
 *   parser = XML::Parser.string('<myxml/>')
 *   parser = XML::Parser.io(File.open('my_file'))
 *
 *  XML::HTMLParser, XML::Reader, XML::SaxParser and
 *  XML::Document work in the same way.
 *
 * LibXML converts all data sources to UTF8 internally before
 * processing them.  By default, LibXML will determine a data
 * source's encoding using the algorithm described on its
 * website[* http://xmlsoft.org/encoding.html].
 *
 * However, its some cases it is possible to tell LibXML
 * the data source's encoding via the constants defined in
 * the Encoding module.
 *
 * Example 1:
 *
 *   parser = XML::Parser.new
 *   parser.input.encoding = XML::Input::ISO_8859_1
 *   parser.io = File.open('some_file', 'rb')
 *   doc = parser.parse
 *
 * Example 2:
 *
 *   parser = XML::HTMLParser.new
 *   parser.encoding = XML::Input::ISO_8859_1
 *   parser.file = "some_file"
 *   doc = parser.parse
 *
 * Example 3:
 *
 *   document = XML::Document.new
 *   encoding_string =  XML::Input.encoding_to_s(XML::Encoding::ISO_8859_1)
 *   document.encoding = document
 *   doc << XML::Node.new */

ID BASE_URL_ATTR;
ID ENCODING_ATTR;
ID FILE_ATTR;
ID STRING_ATTR;
ID IO_ATTR;

static ID READ_METHOD;

/* This method is called by libxml when it wants to read
 more data from a stream. We go with the duck typing
 solution to support StringIO objects. */
int rxml_read_callback(void *context, char *buffer, int len)
{
  VALUE io = (VALUE) context;
  VALUE string = rb_funcall(io, READ_METHOD, 1, INT2NUM(len));
  int size;

  if (string == Qnil)
    return 0;

  size = RSTRING_LEN(string);
  memcpy(buffer, StringValuePtr(string), size);

  return size;
}

/*
 * call-seq:
 *    Input.encoding_to_s(Input::ENCODING) -> "encoding"
 *
 * Converts an encoding contstant defined on the XML::Input
 * class to its text representation.
 */
VALUE rxml_input_encoding_to_s(VALUE klass, VALUE encoding)
{
  char* encodingStr = NULL;

  switch (NUM2INT(encoding))
  {
  case XML_CHAR_ENCODING_ERROR:
    encodingStr = "Error";
    break;
  case XML_CHAR_ENCODING_NONE:
    encodingStr = "None";
    break;
  case XML_CHAR_ENCODING_UTF8:
    encodingStr = "UTF-8";
    break;
  case XML_CHAR_ENCODING_UTF16LE:
    encodingStr = "UTF-16LE";
    break;
  case XML_CHAR_ENCODING_UTF16BE:
    encodingStr = "UTF-16BE";
    break;
  case XML_CHAR_ENCODING_UCS4LE:
    encodingStr = "UCS-4LE";
    break;
  case XML_CHAR_ENCODING_UCS4BE:
    encodingStr = "UCS-4BE";
    break;
  case XML_CHAR_ENCODING_EBCDIC:
    encodingStr = "EBCDIC";
    break;
  case XML_CHAR_ENCODING_UCS4_2143:
    encodingStr = "UCS-4";
    break;
  case XML_CHAR_ENCODING_UCS4_3412:
    encodingStr = "UCS-4";
    break;
  case XML_CHAR_ENCODING_UCS2:
    encodingStr = "UCS-2";
    break;
  case XML_CHAR_ENCODING_8859_1:
    encodingStr = "ISO-8859-1";
    break;
  case XML_CHAR_ENCODING_8859_2:
    encodingStr = "ISO-8859-2";
    break;
  case XML_CHAR_ENCODING_8859_3:
    encodingStr = "ISO-8859-3";
    break;
  case XML_CHAR_ENCODING_8859_4:
    encodingStr = "ISO-8859-4";
    break;
  case XML_CHAR_ENCODING_8859_5:
    encodingStr = "ISO-8859-5";
    break;
  case XML_CHAR_ENCODING_8859_6:
    encodingStr = "ISO-8859-6";
    break;
  case XML_CHAR_ENCODING_8859_7:
    encodingStr = "ISO-8859-7";
    break;
  case XML_CHAR_ENCODING_8859_8:
    encodingStr = "ISO-8859-8";
    break;
  case XML_CHAR_ENCODING_8859_9:
    encodingStr = "ISO-8859-9";
    break;
  case XML_CHAR_ENCODING_2022_JP:
    encodingStr = "ISO-2022-JP";
    break;
  case XML_CHAR_ENCODING_SHIFT_JIS:
    encodingStr = "Shift_JIS";
    break;
  case XML_CHAR_ENCODING_EUC_JP:
    encodingStr = "EUC-JP";
    break;
  case XML_CHAR_ENCODING_ASCII:
    encodingStr = "ASCII";
    break;
  default:
    rb_raise(rb_eArgError, "Unknown encoding.");
  }

  return rb_str_new2(encodingStr);
}

/*
 * call-seq:
 *    initialize -> LibXML::XML::Input instance
 *
 * Initialize a new intput object.
 */
static VALUE rxml_input_initialize(VALUE self)
{
  rb_ivar_set(self, BASE_URL_ATTR, Qnil);
  rb_ivar_set(self, ENCODING_ATTR, INT2NUM(XML_CHAR_ENCODING_UTF8));
  return self;
}

/*
 * call-seq:
 *    input.FILE -> "FILE"
 *
 * Obtain the FILE this parser will read from.
 */
static VALUE rxml_input_file_get(VALUE self)
{
  return rb_ivar_get(self, FILE_ATTR);
}

/*
 * call-seq:
 *    input.FILE = "FILE"
 *
 * Set the FILE this parser will read from.
 */
static VALUE rxml_input_file_set(VALUE self, VALUE FILE)
{
  Check_Type(FILE, T_STRING);
  rb_ivar_set(self, FILE_ATTR, FILE);
  rb_ivar_set(self, IO_ATTR, Qnil);
  rb_ivar_set(self, STRING_ATTR, Qnil);
  return self;
}

/*
 * call-seq:
 *    input.string -> "string"
 *
 * Obtain the string this parser will read from.
 */
static VALUE rxml_input_string_get(VALUE self)
{
  return rb_ivar_get(self, STRING_ATTR);
}

/*
 * call-seq:
 *    input.string = "string"
 *
 * Set the string this parser will read from.
 */
static VALUE rxml_input_string_set(VALUE self, VALUE string)
{
  Check_Type(string, T_STRING);
  rb_ivar_set(self, FILE_ATTR, Qnil);
  rb_ivar_set(self, IO_ATTR, Qnil);
  rb_ivar_set(self, STRING_ATTR, string);
  return self;
}

/*
 * call-seq:
 *    input.io -> IO
 *
 * Obtain the IO instance this parser works with.
 */
static VALUE rxml_input_io_get(VALUE self)
{
  return rb_ivar_get(self, IO_ATTR);
}

/*
 * call-seq:
 *    input.io = IO
 *
 * Set the IO instance this parser works with.
 */
static VALUE rxml_input_io_set(VALUE self, VALUE io)
{
  rb_ivar_set(self, FILE_ATTR, Qnil);
  rb_ivar_set(self, IO_ATTR, io);
  rb_ivar_set(self, STRING_ATTR, Qnil);
  return self;
}

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_xml_input(void)
{
  BASE_URL_ATTR = rb_intern("@base_url");
  ENCODING_ATTR = rb_intern("@encoding");
  FILE_ATTR = rb_intern("@file");
  IO_ATTR = rb_intern("@io");
  STRING_ATTR = rb_intern("@string");

  READ_METHOD = rb_intern("read");

  cXMLInput = rb_define_class_under(mXML, "Input", rb_cObject);
  rb_define_singleton_method(cXMLInput, "encoding_to_s", rxml_input_encoding_to_s, 1);

  rb_define_const(cXMLInput, "UNDEFINED", INT2NUM(XPATH_UNDEFINED));
  rb_define_const(cXMLInput, "ERROR", INT2NUM(XML_CHAR_ENCODING_ERROR)); /* No char encoding detected */
  rb_define_const(cXMLInput, "NONE", INT2NUM(XML_CHAR_ENCODING_NONE)); /* No char encoding detected */
  rb_define_const(cXMLInput, "UTF_8", INT2NUM(XML_CHAR_ENCODING_UTF8)); /* UTF-8 */
  rb_define_const(cXMLInput, "UTF_16LE", INT2NUM(XML_CHAR_ENCODING_UTF16LE)); /* UTF-16 little endian */
  rb_define_const(cXMLInput, "UTF_16BE", INT2NUM(XML_CHAR_ENCODING_UTF16BE)); /* UTF-16 big endian */
  rb_define_const(cXMLInput, "UCS_4LE", INT2NUM(XML_CHAR_ENCODING_UCS4LE)); /* UCS-4 little endian */
  rb_define_const(cXMLInput, "UCS_4BE", INT2NUM(XML_CHAR_ENCODING_UCS4BE)); /* UCS-4 big endian */
  rb_define_const(cXMLInput, "EBCDIC", INT2NUM(XML_CHAR_ENCODING_EBCDIC)); /* EBCDIC uh! */
  rb_define_const(cXMLInput, "UCS_4_2143", INT2NUM(XML_CHAR_ENCODING_UCS4_2143)); /* UCS-4 unusual ordering */
  rb_define_const(cXMLInput, "UCS_4_3412", INT2NUM(XML_CHAR_ENCODING_UCS4_3412)); /* UCS-4 unusual ordering */
  rb_define_const(cXMLInput, "UCS_2", INT2NUM(XML_CHAR_ENCODING_UCS2)); /* UCS-2 */
  rb_define_const(cXMLInput, "ISO_8859_1", INT2NUM(XML_CHAR_ENCODING_8859_1)); /* ISO-8859-1 ISO Latin 1 */
  rb_define_const(cXMLInput, "ISO_8859_2", INT2NUM(XML_CHAR_ENCODING_8859_2)); /* ISO-8859-2 ISO Latin 2 */
  rb_define_const(cXMLInput, "ISO_8859_3", INT2NUM(XML_CHAR_ENCODING_8859_3)); /* ISO-8859-3 */
  rb_define_const(cXMLInput, "ISO_8859_4", INT2NUM(XML_CHAR_ENCODING_8859_4)); /* ISO-8859-4 */
  rb_define_const(cXMLInput, "ISO_8859_5", INT2NUM(XML_CHAR_ENCODING_8859_5)); /* ISO-8859-5 */
  rb_define_const(cXMLInput, "ISO_8859_6", INT2NUM(XML_CHAR_ENCODING_8859_6)); /* ISO-8859-6 */
  rb_define_const(cXMLInput, "ISO_8859_7", INT2NUM(XML_CHAR_ENCODING_8859_7)); /* ISO-8859-7 */
  rb_define_const(cXMLInput, "ISO_8859_8", INT2NUM(XML_CHAR_ENCODING_8859_8)); /* ISO-8859-8 */
  rb_define_const(cXMLInput, "ISO_8859_9", INT2NUM(XML_CHAR_ENCODING_8859_9)); /* ISO-8859-9 */
  rb_define_const(cXMLInput, "ISO_2022_JP", INT2NUM(XML_CHAR_ENCODING_2022_JP)); /* ISO-2022-JP */
  rb_define_const(cXMLInput, "SHIFT_JIS", INT2NUM(XML_CHAR_ENCODING_SHIFT_JIS)); /* Shift_JIS */
  rb_define_const(cXMLInput, "EUC_JP", INT2NUM(XML_CHAR_ENCODING_EUC_JP)); /* EUC-JP */
  rb_define_const(cXMLInput, "ASCII", INT2NUM(XML_CHAR_ENCODING_ASCII)); /* pure ASCII */

  rb_define_attr(cXMLInput, "base_url", 1, 1);
  rb_define_attr(cXMLInput, "encoding", 1, 1);

  rb_define_method(cXMLInput, "initialize", rxml_input_initialize, 0);
  rb_define_method(cXMLInput, "file", rxml_input_file_get, 0);
  rb_define_method(cXMLInput, "file=", rxml_input_file_set, 1);
  rb_define_method(cXMLInput, "string", rxml_input_string_get, 0);
  rb_define_method(cXMLInput, "string=", rxml_input_string_set, 1);
  rb_define_method(cXMLInput, "io", rxml_input_io_get, 0);
  rb_define_method(cXMLInput, "io=", rxml_input_io_set, 1);
}
