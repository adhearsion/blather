/* $Id: ruby_xml_attr.h 666 2008-12-07 00:16:50Z cfis $ */

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_ATTR__
#define __RXML_ATTR__

extern VALUE cXMLAttr;

void ruby_init_xml_attr(void);
VALUE rxml_attr_new(xmlAttrPtr xattr);
VALUE rxml_attr_value_get(VALUE self);
VALUE rxml_attr_value_set(VALUE self, VALUE val);
void rxml_attr_free(xmlAttrPtr xattr);
VALUE rxml_attr_wrap(xmlAttrPtr xattr);
#endif
