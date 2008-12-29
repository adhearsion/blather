/* $Id $ */

#ifndef __RXML_XPATH_OBJECT__
#define __RXML_XPATH_OBJECT__

extern VALUE cXMLXPathObject;

void ruby_init_xml_xpath_object(void);
VALUE rxml_xpath_object_wrap(xmlXPathObjectPtr xpop);

#endif
