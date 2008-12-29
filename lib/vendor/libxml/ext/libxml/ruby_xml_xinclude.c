/* $Id: ruby_xml_xinclude.c 650 2008-11-30 03:40:22Z cfis $ */

#include "ruby_libxml.h"
#include "ruby_xml_xinclude.h"

VALUE cXMLXInclude;

/*
 * Document-class: LibXML::XML::XInclude
 *
 * The ruby bindings do not currently expose libxml's
 * XInclude fuctionality.
 */

// Rdoc needs to know
#ifdef RDOC_NEVER_DEFINED
mLibXML = rb_define_module("LibXML");
mXML = rb_define_module_under(mLibXML, "XML");
#endif

void ruby_init_xml_xinclude(void)
{
  cXMLXInclude = rb_define_class_under(mXML, "XInclude", rb_cObject);
}
