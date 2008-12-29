/* $Id: rxml_parser.h 39 2006-02-21 20:40:16Z roscopeco $ */

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RXML_INPUT__
#define __RXML_INPUT__

extern VALUE cXMLInput;

extern ID BASE_URL_ATTR;
extern ID ENCODING_ATTR;
extern ID FILE_ATTR;
extern ID IO_ATTR;
extern ID STRING_ATTR;

void ruby_init_xml_input();
int rxml_read_callback(void *context, char *buffer, int len);
VALUE rxml_input_encoding_to_s(VALUE klass, VALUE encoding);

#endif
