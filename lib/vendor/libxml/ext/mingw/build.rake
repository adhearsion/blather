# We can't use Ruby's standard build procedures
# on Windows because the Ruby executable is
# built with VC++ while here we want to build
# with MingW.  So just roll our own...

require 'rake/clean'
require 'rbconfig'

RUBY_INCLUDE_DIR = Config::CONFIG["archdir"]
RUBY_BIN_DIR = Config::CONFIG["bindir"]
RUBY_LIB_DIR = Config::CONFIG["libdir"]
RUBY_SHARED_LIB = Config::CONFIG["LIBRUBY"]
RUBY_SHARED_DLL = RUBY_SHARED_LIB.gsub(/lib$/, 'dll')

EXTENSION_NAME = "libxml_ruby.#{Config::CONFIG["DLEXT"]}"
# MingW insists the import library is .dll.a
EXTENSION_LIB_NAME = "libxml_ruby.dll.a"

CLEAN.include('*.o')
CLOBBER.include(EXTENSION_NAME)
CLOBBER.include(EXTENSION_LIB_NAME)

task :default => "libxml"

SRC = FileList['../libxml/*.c']
OBJ = SRC.collect do |file_name|
  File.basename(file_name).ext('o')
end

SRC.each do |srcfile|
  objfile = File.basename(srcfile).ext('o')
  file objfile => srcfile do
    command = "gcc -c -O2 -Wall -o #{objfile} -I/usr/local/include #{srcfile} -I#{RUBY_INCLUDE_DIR}"
    sh "sh -c '#{command}'" 
  end
end

file "libxml" => OBJ do
  command = "gcc -shared -o #{EXTENSION_NAME} -Wl,--out-implib,#{EXTENSION_LIB_NAME} -L/usr/local/lib #{OBJ} -lxml2 #{RUBY_BIN_DIR}/#{RUBY_SHARED_DLL}" 
  sh "sh -c '#{command}'" 
end
