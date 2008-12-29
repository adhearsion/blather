# $Id: libxml.rb 666 2008-12-07 00:16:50Z cfis $ 
# Please see the LICENSE file for copyright and distribution information 

# If running on Windows, then add the current directory to the PATH
# for the current process so it can find the pre-built libxml2 and 
# iconv2 shared libraries (dlls).
if RUBY_PLATFORM.match(/mswin/i)
  ENV['PATH'] += ";#{File.dirname(__FILE__)}"
end

# Load the C-based binding.
require 'libxml_ruby'

# Load Ruby supporting code.
require 'libxml/error'
require 'libxml/parser'
require 'libxml/parser_options'
require 'libxml/parser_context'
require 'libxml/document'
require 'libxml/namespaces'
require 'libxml/namespace'
require 'libxml/node'
require 'libxml/ns'
require 'libxml/attributes'
require 'libxml/attr'
require 'libxml/tree'
require 'libxml/reader'
require 'libxml/html_parser'
require 'libxml/sax_parser'
require 'libxml/sax_callbacks'
require 'libxml/xpath_object'

# Deprecated
require 'libxml/properties'

# Map the LibXML module into the XML module for both backwards
# compatibility and ease of use.
# 
# DEPRECATED: Use require 'xml' instead!
#
# include LibXML

