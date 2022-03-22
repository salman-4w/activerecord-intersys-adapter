#!/usr/bin/env ruby

require "mkmf"

raise 'We don\'t test library on Windows, but try to use VS2005 solution from win32 directory to build this library.' if RUBY_PLATFORM.match(/mswin/)
  

CONFIG["CC"] = "gcc -g" 

unless cache_install_path = with_config('cache-install-path')
  puts "Use --with-cache-install-path parameter to provide path to Intersystems Cache install directory"
  exit 1
end

@cache_install_path = cache_install_path

def locations(suffix)
  [@cache_install_path + suffix]
end                                                                                             

def include_locations
  locations("/dev/cpp/include") + ["../ext/sql_include"]
end

def library_locations
  locations("/dev/cpp/lib")
end

def include_flags
  " "+(include_locations.map { |place| "-I"+place} + ["-Wall"]).join(" ")
end

def link_flags
  " "+(library_locations.map { |place| "-L"+place} + ["-Wall"]).join(" ")
end

$CFLAGS << include_flags
$LDFLAGS << link_flags

have_header "c_api.h"
$CFLAGS << ' -Isql_include '
have_header "sql.h"
have_header "sqlext.h"

unless RUBY_PLATFORM.match(/darwin/)
  find_library "cbind", "cbind_alloc_db",*library_locations
end

# Define RUBY_18 macro if we are compiling for 1.8
$CFLAGS << ' -DRUBY_18' if RUBY_VERSION =~ /1.8/

create_makefile 'intersys_bindings'
