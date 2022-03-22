require "intersys/bindings/serial"
require "intersys/bindings/errors"

require "active_record/connection_adapters/intersys_adapter"
require "active_record/attribute_methods/ext/attribute_methods"
require "active_record/validations/ext/uniqueness"
require "active_record/ext/associations"
require "active_record/ext/persistence"
require "active_record/ext/base"

require "arel/visitors/intersys"

require "activerecord_intersys_adapter/railtie.rb" if defined?(Rails)
