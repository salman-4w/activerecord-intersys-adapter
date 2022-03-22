module ActiveRecord
  module ConnectionAdapters
    module Intersys
      module SchemaStatements
        def native_database_types
          {
            :primary_key => "%Library.String".freeze,
            :string      => { :name => "%Library.String" },
            # :text        => { :name => "text" },
            :integer     => { :name => "%Library.Integer" },
            :float       => { :name => "%Library.Float" },
            # :decimal     => { :name => "decimal" },
            # :datetime    => { :name => "timestamp" },
            # :timestamp   => { :name => "timestamp" },
            # :time        => { :name => "time" },
            :date        => { :name => "%Library.Date" },
            # :binary      => { :name => "bytea" },
            :boolean     => { :name => "%Library.Boolean" },
            # :xml         => { :name => "xml" }
          }
        end

        # Public: Fetches unpackaged table names from the database
        # Returns array of table names
        def tables(name = nil)
          sql = <<-SQL
            SELECT parent FROM %Dictionary.CompiledProperty
            WHERE parent->system = 0
            GROUP BY parent
          SQL
          exec_query(sql, "SCHEMA").map { |row| unpackaged_table(row["parent"]) }
        end

        # Returns the list of all column definitions for a table.
        def columns(table_name, name = nil)
          table_name = packaged_table(table_name)

          columns_cache_for table_name, :regular do
            # retreive only regular not transient not stream columns and belongs_to columns
            conditions = <<-SQL
              (RuntimeType != '%Library.RelationshipObject'
                OR Cardinality IN ('one', 'parent'))
              AND RuntimeType NOT IN (#{sanitized_stream_types})
              AND Transient = 0
            SQL

            columns = columns_by_type_conditions(conditions, table_name)
            columns << IntersysColumn.new(primary_key, nil, "%Library.String", false)
            columns
          end
        end

        # Returns subset of table's columns that are serial objects
        def serial_columns(table_name)
          columns(table_name).select { |c| c.serial_object? }
        end

        def stream_columns(table_name, name = nil)
          table_name = packaged_table(table_name)

          columns_cache_for table_name, :stream do
            # retreive only regular not transient stream columns
            conditions = "RuntimeType IN (#{sanitized_stream_types}) AND Transient = 0"
            columns_by_type_conditions(conditions, table_name)
          end
        end

        private

        def columns_cache_for(table_name, type)
          columns_cache = (type == :stream) ? stream_columns_cache : regular_columns_cache

          if !columns_cache[table_name] && block_given?
            columns_cache[table_name] = yield
          end

          columns_cache[table_name]
        end

        def regular_columns_cache
          @regular_columns_cache ||= {}
        end

        def stream_columns_cache
          @stream_columns_cache ||= {}
        end

        def reset_columns_cache_for(table_name)
          regular_columns_cache[table_name] = nil
          stream_columns_cache[table_name] = nil
        end

        def sanitized_stream_types
          @sanitized_stream_types ||= ::Intersys::Callable::STREAM_DATABASE_TYPES.map { |type| "'#{type}'" }.join(',')
        end

        def columns_by_type_conditions(conditions, table_name)
          # DirectRefOnSet is true (1) when the property can be assigned directly and false (0) when not.
          # Usually it equals 0 for all non native column types
          sql =<<-SQL
            SELECT Name, RuntimeType, InitialExpression, Calculated, DirectRefOnSet
            FROM %Dictionary.CompiledProperty
            WHERE parent->system = 0
              AND parent->Name = '#{quote_table_name(table_name)}'
              AND #{conditions}
          SQL

          columns = exec_query(sql, "SCHEMA").rows.map do |name, type, default, calculated, direct_ref_on_set|
            is_serial_object = false

            if ::Intersys::Serial::TableMap.include?(type)
              is_serial_object = true
            end

            default = (default == "\"\"") ? nil : default
            IntersysColumn.new(name, default, type, false, calculated, !direct_ref_on_set, is_serial_object)
          end
          columns.compact
        end
      end
    end
  end
end
