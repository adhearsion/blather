#include "ruby_libxml.h"
#include "ruby_xml_dtd.h"

/*
 * Document-class: LibXML::XML::Dtd
 *
 * The XML::Dtd class is used to prepare DTD's for validation of xml
 * documents.
 *
 * DTDs can be created from a string or a pair of public and system identifiers.
 * Once a Dtd object is instantiated, an XML document can be validated by the
 * XML::Document#validate method providing the XML::Dtd object as parameeter.
 * The method will raise an exception if the document is
 * not valid.
 *
 * Basic usage:
 *
 *  # parse DTD
 *  dtd = XML::Dtd.new(<<EOF)
 *  <!ELEMENT root (item*) >
 *  <!ELEMENT item (#PCDATA) >
 *  EOF
 *
 *  # parse xml document to be validated
 *  instance = XML::Document.file('instance.xml')
 *
 *  # validate
 *  instance.validate(dtd)
 */

VALUE cXMLDtd;

void rxml_dtd_free(xmlDtdPtr xdtd)
{
  xmlFreeDtd(xdtd);
}

static VALUE rxml_dtd_alloc(VALUE klass)
{
  return Data_Wrap_Struct(klass, NULL, rxml_dtd_free, NULL);
}

/*
 * call-seq:
 *    XML::Dtd.new("public system") -> dtd
 *    XML::Dtd.new("public", "system") -> dtd
 *
 * Create a new Dtd from the specified public and system
 * identifiers.
 */
static VALUE rxml_dtd_initialize(int argc, VALUE *argv, VALUE self)
{
  VALUE external, system, dtd_string;
  xmlParserInputBufferPtr buffer;
  xmlCharEncoding enc = XML_CHAR_ENCODING_NONE;
  xmlChar *new_string;
  xmlDtdPtr xdtd;

  // 1 argument -- string               --> parsujeme jako dtd
  // 2 argumenty -- public, system      --> bude se hledat
  switch (argc)
  {
  case 2:
    rb_scan_args(argc, argv, "20", &external, &system);

    Check_Type(external, T_STRING);
    Check_Type(system, T_STRING);

    xdtd = xmlParseDTD((xmlChar*) StringValuePtr(external),
        (xmlChar*) StringValuePtr(system));

    if (xdtd == NULL)
      rxml_raise(&xmlLastError);

    DATA_PTR( self) = xdtd;

    xmlSetTreeDoc((xmlNodePtr) xdtd, NULL);
    break;

  case 1:
    rb_scan_args(argc, argv, "10", &dtd_string);
    Check_Type(dtd_string, T_STRING);

    /* Note that buffer is freed by xmlParserInputBufferPush*/
    buffer = xmlAllocParserInputBuffer(enc);
    new_string = xmlStrdup((xmlChar*) StringValuePtr(dtd_string));
    xmlParserInputBufferPush(buffer, xmlStrlen(new_string),
        (const char*) new_string);

    xdtd = xmlIOParseDTD(NULL, buffer, enc);

    if (xdtd == NULL)
      rxml_raise(&xmlLastError);

    xmlFree(new_string);

    DATA_PTR( self) = xdtd;
    break;

  default:
    rb_raise(rb_eArgError, "wrong number of arguments (need 1 or 2)");
  }

  return self;
}

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_xml_dtd()
{
  cXMLDtd = rb_define_class_under(mXML, "Dtd", rb_cObject);
  rb_define_alloc_func(cXMLDtd, rxml_dtd_alloc);
  rb_define_method(cXMLDtd, "initialize", rxml_dtd_initialize, -1);
}

