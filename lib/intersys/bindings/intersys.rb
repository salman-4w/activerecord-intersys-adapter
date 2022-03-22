#!/usr/bin/env ruby
require 'dl/import'
require 'enumerator'

#
# Module, keeping all classes, required to work with Cache via object and SQL interfaces
module Intersys
if RUBY_VERSION =~ /1.8/
  extend DL::Importable
else
  extend DL::Importer
end

  load_error = nil
  # try to load libraries for MacOSX and Linux
  %w{ libcbind.dylib libcbind.so }.each do |lib|
    begin
      dlload(lib)
      load_error = nil
      break
    rescue StandardError => load_error
    end
  end

  puts load_error if load_error

  if RUBY_VERSION =~ /1.8/
    require File.dirname(__FILE__) + '/ruby18_hacks'
  end

  require File.dirname(__FILE__) + '/../../intersys_bindings'
  require File.dirname(__FILE__) + '/errors'
  require File.dirname(__FILE__) + '/object'
  require File.dirname(__FILE__) + '/callable'
  require File.dirname(__FILE__) + '/stream'
  require File.dirname(__FILE__) + '/serial'
  require File.dirname(__FILE__) + '/reflection'
  require File.dirname(__FILE__) + '/sql'


  class Method
    def description
      args = []
      each_argument do |arg|
        descr = ""
        descr << "out " if arg.by_ref?
        descr << "#{arg.cache_type} #{arg.name}"
        descr << (' = '+arg.default) if arg.default
        args << descr
      end
      "#{cache_type} #{name}("+args.join(', ')+")"
    end
  end
end
