/* $Id: ruby_xml_parser_context.h 666 2008-12-07 00:16:50Z cfis $ */

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_PARSER_CONTEXT__
#define __RXML_PARSER_CONTEXT__

extern VALUE cXMLParserContext;

void ruby_init_xml_parser_context(void);
VALUE rxml_parser_context_wrap(xmlParserCtxtPtr ctxt);

#endif
