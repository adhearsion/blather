#!/usr/bin/env ruby

require 'rbconfig'

def method_missing(s, *args)
  if v = Config::CONFIG[s] || Config::CONFIG[s.upcase]
    return v
  else
    puts "missing: #{s}"
    super
  end
end

require 'mkmf'

if defined?(CFLAGS)
  if CFLAGS.index(CONFIG['CCDLFLAGS'])
    $CFLAGS = CFLAGS + ' ' + CONFIG['CCDLFLAGS']
  else
    $CFLAGS = CFLAGS
  end
else
  $CFLAGS = CONFIG['CFLAGS']
end
$LDFLAGS = CONFIG['LDFLAGS']
$LIBPATH.push(Config::CONFIG['libdir'])

def crash(str)
  printf(" extconf failure: %s\n", str)
  exit 1
end

dir_config('iconv')
dir_config('xml2')
dir_config('zlib')

have_library('socket','socket')
have_library('nsl','gethostbyname')

unless have_library('m', 'atan')
  # try again for gcc 4.0
  saveflags = $CFLAGS
  $CFLAGS += ' -fno-builtin'
  unless have_library('m', 'atan')
    crash('need libm')
  end
  $CFLAGS = saveflags
end

unless have_library('z', 'inflate') or
       have_library('zlib', 'inflate') or
       have_library('zlib1', 'inflate')
  crash('need zlib')
else
  $defs.push('-DHAVE_ZLIB_H')
end

unless have_library('iconv','iconv_open') or 
       have_library('iconv','libiconv_open') or
       have_library('libiconv', 'libiconv_open') or
       have_library('libiconv', 'iconv_open') or
       have_library('c','iconv_open') or
       have_library('recode','iconv_open') or
       have_library('iconv')
  crash(<<EOL)
need libiconv.

Install the libiconv or try passing one of the following options
to extconf.rb:

  --with-iconv-dir=/path/to/iconv
  --with-iconv-lib=/path/to/iconv/lib
  --with-iconv-include=/path/to/iconv/include
EOL
end

unless (have_library('xml2', 'xmlParseDoc') or
        have_library('libxml2', 'xmlParseDoc') or
        find_library('xml2', 'xmlParseDoc', '/opt/lib', '/usr/local/lib', '/usr/lib')) and 
       (have_header('libxml/xmlversion.h') or
        find_header('libxml/xmlversion.h',
                    "#{CONFIG['prefix']}/include",
                    "#{CONFIG['prefix']}/include/libxml2",
                    '/opt/include/libxml2', 
                    '/usr/local/include/libxml2', 
                    '/usr/include/libxml2'))
  crash(<<EOL)
need libxml2.

    Install the library or try one of the following options to extconf.rb:

      --with-xml2-dir=/path/to/libxml2
      --with-xml2-lib=/path/to/libxml2/lib
      --with-xml2-include=/path/to/libxml2/include
EOL
end

unless have_func('xmlDocFormatDump')
  crash('Your version of libxml2 is too old.  Please upgrade.')
end

unless have_func('docbCreateFileParserCtxt')
  crash('Need docbCreateFileParserCtxt')
end

# For FreeBSD add /usr/local/include
$INCFLAGS << " -I/usr/local/include"

$CFLAGS << ' ' << $INCFLAGS
#$INSTALLFILES = [["libxml.rb", "$(RUBYLIBDIR)", "../xml"]]

create_header()
create_makefile('libxml_ruby')

__END__

SHELL = /bin/sh

#### Start of system configuration section. ####

# I think we can remove all the parts related to the install target
# since setup.rb and RubyGems handles that on their own. Correct?

srcdir = .
topdir = #{archdir}  #/usr/lib/ruby/1.8/x86_64-linux
hdrdir = $(topdir)
VPATH = $(srcdir):$(topdir):$(hdrdir)
prefix = $(DESTDIR)/usr
exec_prefix = $(DESTDIR)/usr
sitedir = $(DESTDIR)/usr/local/lib/site_ruby
rubylibdir = $(libdir)/ruby/$(ruby_version)
docdir = $(datarootdir)/doc/$(PACKAGE)
dvidir = $(docdir)
datarootdir = $(prefix)/share
archdir = $(rubylibdir)/$(arch)
sbindir = $(exec_prefix)/sbin
psdir = $(docdir)
localedir = $(datarootdir)/locale
htmldir = $(docdir)
datadir = $(datarootdir)
includedir = $(prefix)/include
infodir = $(prefix)/share/info
sysconfdir = $(DESTDIR)/etc
mandir = $(prefix)/share/man
libdir = $(DESTDIR)/usr/lib
sharedstatedir = $(prefix)/com
oldincludedir = $(DESTDIR)/usr/include
pdfdir = $(docdir)
sitearchdir = $(sitelibdir)/$(sitearch)
bindir = $(exec_prefix)/bin
localstatedir = $(DESTDIR)/var
sitelibdir = $(sitedir)/$(ruby_version)
libexecdir = $(prefix)/lib/ruby1.8

CC = cc
LIBRUBY = $(LIBRUBY_SO)
LIBRUBY_A = lib$(RUBY_SO_NAME)-static.a
LIBRUBYARG_SHARED = -l$(RUBY_SO_NAME)
LIBRUBYARG_STATIC = -l$(RUBY_SO_NAME)-static

RUBY_EXTCONF_H = extconf.h
CFLAGS   =  -fPIC -fno-strict-aliasing -g -O2  -fPIC -I. -I/usr/lib/ruby/1.8/x86_64-linux -I. -I/usr/include/libxml2 
INCFLAGS = -I. -I. -I/usr/lib/ruby/1.8/x86_64-linux -I. -I/usr/include/libxml2
CPPFLAGS = -DRUBY_EXTCONF_H=\"$(RUBY_EXTCONF_H)\" 
CXXFLAGS = $(CFLAGS) 
DLDFLAGS = -L.  -rdynamic -Wl,-export-dynamic  
LDSHARED = $(CC) -shared
AR = ar
EXEEXT = 

RUBY_INSTALL_NAME = ruby1.8
RUBY_SO_NAME = ruby1.8
arch = x86_64-linux
sitearch = x86_64-linux
ruby_version = 1.8
ruby = /usr/bin/ruby1.8
RUBY = $(ruby)
RM = rm -f
MAKEDIRS = mkdir -p
INSTALL = /usr/bin/install -c
INSTALL_PROG = $(INSTALL) -m 0755
INSTALL_DATA = $(INSTALL) -m 644
COPY = cp

preload = 

libpath = . $(libdir) /usr/lib
LIBPATH =  -L"." -L"$(libdir)" -L"/usr/lib"
DEFFILE = 

CLEANFILES = 
DISTCLEANFILES = 

extout = 
extout_prefix = 
target_prefix = /xml
LOCAL_LIBS = 
LIBS = $(LIBRUBYARG_SHARED) -lxml2 -lc -lz -lm -lnsl  -lpthread -ldl -lcrypt -lm   -lc

SRCS = #{srcs.join(' ')}
OBJS = #{objs.join(' ')}

TARGET = #{target}
DLLIB = $(TARGET).so
EXTSTATIC = 
STATIC_LIB = 

RUBYCOMMONDIR = $(sitedir)$(target_prefix)
RUBYLIBDIR    = $(sitelibdir)$(target_prefix)
RUBYARCHDIR   = $(sitearchdir)$(target_prefix)

TARGET_SO     = $(DLLIB)
CLEANLIBS     = $(TARGET).so $(TARGET).il? $(TARGET).tds $(TARGET).map
CLEANOBJS     = *.o *.a *.s[ol] *.pdb *.exp *.bak

all:    $(DLLIB)
static:   $(STATIC_LIB)

clean:
    @-$(RM) $(CLEANLIBS) $(CLEANOBJS) $(CLEANFILES)

distclean:  clean
    @-$(RM) Makefile $(RUBY_EXTCONF_H) conftest.* mkmf.log
    @-$(RM) core ruby$(EXEEXT) *~ $(DISTCLEANFILES)

realclean:  distclean
install: install-so install-rb

install-so: $(RUBYARCHDIR)
install-so: $(RUBYARCHDIR)/$(DLLIB)
$(RUBYARCHDIR)/$(DLLIB): $(DLLIB)
  $(INSTALL_PROG) $(DLLIB) $(RUBYARCHDIR)
install-rb: pre-install-rb install-rb-default
install-rb-default: pre-install-rb-default
pre-install-rb: Makefile
pre-install-rb-default: Makefile
$(RUBYARCHDIR):
  $(MAKEDIRS) $@

site-install: site-install-so site-install-rb
site-install-so: install-so
site-install-rb: install-rb

.SUFFIXES: .c .m .cc .cxx .cpp .C .o

.cc.o:
  $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cxx.o:
  $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.cpp.o:
  $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.C.o:
  $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) -c $<

.c.o:
  $(CC) $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) -c $<

$(DLLIB): $(OBJS)
  @-$(RM) $@
  $(LDSHARED) -o $@ $(OBJS) $(LIBPATH) $(DLDFLAGS) $(LOCAL_LIBS) $(LIBS)


$(OBJS): ruby.h defines.h $(RUBY_EXTCONF_H)

