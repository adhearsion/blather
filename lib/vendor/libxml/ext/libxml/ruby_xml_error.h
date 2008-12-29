/* $Id: rxml_ns.h 324 2008-07-08 23:00:02Z cfis $ */

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_ERROR__
#define __RXML_ERROR__

extern VALUE eXMLError;

void ruby_init_xml_error();
VALUE rxml_error_wrap(xmlErrorPtr xerror);
void rxml_raise(xmlErrorPtr xerror);

#endif
