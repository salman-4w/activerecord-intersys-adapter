require "active_record"
require "active_record/connection_adapters/abstract_adapter"
require "active_record/connection_adapters/intersys_column"
require "active_record/connection_adapters/intersys/schema_statements"

module ActiveRecord
  class Base
    def self.intersys_connection(config)
      require "intersys/bindings/intersys"
      ConnectionAdapters::IntersysAdapter.new(config, logger)
    end
  end

  module ConnectionAdapters
    class IntersysAdapter < AbstractAdapter
      include Intersys::SchemaStatements

      attr_reader :connection_options

      def initialize(config, logger=nil)
        @connection_options = config.symbolize_keys
        if @connection_options[:port].present?
          @connection_options[:port] = @connection_options[:port].to_s
        end
        @connection_options[:objects_readonly] ||= true
        # default package to Caché default, then raise a fuss about it
        @connection_options[:package] ||= "User"

        @connection = ::Intersys::Database.new(@connection_options)
        super(raw_connection, logger)
        @visitor = Arel::Visitors::Intersys.new self
      end

      def adapter_name
        "Intersys"
      end

      def supports_migrations?
        false
      end

      def supports_primary_key?
        true
      end

      def primary_key(table_name=nil)
        "ID"
      end

      # A Caché 'namespace' is a logical superstructure outside of a database
      def namespace
        @connection_options[:namespace]
      end

      # A Caché 'package' is akin to a Ruby module or Postgres schema.
      # At some point we may want to map these to real Ruby modules, but for
      # now we'll just have a single package per connection and use it
      # all the time
      def package
        return @package if defined? @package

        if @connection_options[:package] == "User"
          raise <<-MSG
          The default 'User' package is incomptabile due to its usage of the
          SQLUser table schema. Please create a custom package name instead
          MSG
        end

        @package = @connection_options[:package]
      end

      # Prefixes table name with Caché package
      def packaged_table(name)
        name.match(package) ? name : "#{package}.#{name}"
      end

      # Removes Caché package from table name
      def unpackaged_table(name)
        name[/\.?(\w+)$/, 1]
      end

      # DATABASE STATEMENTS ========================================

      # Executes +sql+ statement in the context of this connection using
      # +binds+ as the bind substitutes. +name+ is logged along with
      # the executed +sql+ statement.
      #
      # Column names are returned in Ruby-style underscore
      def exec_query(sql, name=nil, binds=[])
        log(sql, name, binds) do
          query = @connection.prepare(sql)
          query.bind_params binds.map { |col, val| type_cast(val, col) }
          query.execute

          result = if query.columns.any?
            ActiveRecord::Result.new(query.columns.map(&:underscore), query.rows)
          else
            true
          end

          query.close
          return result
        end
      end
      alias :execute :exec_query

      # Returns an array of record hashes with the column names as keys and
      # column values as values.
      def select(sql, name=nil, binds=[])
        exec_query(sql, name, binds).to_a
      end

      # Returns an array of arrays containing the field values.
      # Order is the same as that returned by +columns+.
      def select_rows(sql, name=nil)
        exec_query(sql, name).rows
      end

      # QUOTING ====================================================
      def quoted_true
        "1"
      end

      def quoted_false
        "0"
      end
    end
  end
end
