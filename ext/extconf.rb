require 'mkmf'

flags = []

case RUBY_PLATFORM.split('-',2)[1]
when 'mswin32', 'mingw32', 'bccwin32'
  unless have_header('windows.h') and
      have_header('winsock.h') and
      have_library('kernel32') and
      have_library('rpcrt4') and
      have_library('gdi32')
    exit
  end

  flags << "-D OS_WIN32"
  flags << '-D BUILD_FOR_RUBY'
  flags << "-EHs"
  flags << "-GR"

  dir_config('xml2')
  exit unless have_library('xml2') && have_header('libxml/parser.h')

when /solaris/
  unless have_library('pthread') and
	have_library('nsl') and
	have_library('socket')
	  exit
  end

  flags << '-D OS_UNIX'
  flags << '-D OS_SOLARIS8'
  flags << '-D BUILD_FOR_RUBY'

  dir_config('xml2')
  exit unless have_library('xml2') && find_header('libxml/parser.h', '/usr/include/libxml2')

  # on Unix we need a g++ link, not gcc.
  #CONFIG['LDSHARED'] = "$(CXX) -shared"

when /darwin/
  flags << '-DOS_UNIX'
  flags << '-DBUILD_FOR_RUBY'

  dir_config('xml2')
  exit unless have_library('xml2') && find_header('libxml/parser.h', '/usr/include/libxml2')
  # on Unix we need a g++ link, not gcc.
  #CONFIG['LDSHARED'] = "$(CXX) " + CONFIG['LDSHARED'].split[1..-1].join(' ')

else
  unless have_library('pthread')
	  exit
  end

  flags << '-DOS_UNIX'
  flags << '-DBUILD_FOR_RUBY'

  dir_config('xml2')
  exit unless have_library('xml2') && find_header('libxml/parser.h', '/usr/include/libxml2')
  # on Unix we need a g++ link, not gcc.
  #CONFIG['LDSHARED'] = "$(CXX) -shared"
end

$CFLAGS += ' ' + flags.join(' ')

create_makefile "push_parser"
