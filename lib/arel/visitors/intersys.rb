# extend as few visitor methods as possible to convert Ruby-style
# attribute names to Caché-style attribute names
module Arel
  module Visitors
    class Intersys < Arel::Visitors::ToSql

      private

      # in select statements, the projections need to have the source table
      # added when they are sql literals (ie - coming from "select" scope)
      #
      # special cases:
      #
      # 1) "1" is SELECTed sometimes to check for existence, skip it
      # 2) serial columns need to have their prefixed attributes included
      # 3) some literals already have the table name in them, skip em
      def visit_Arel_Nodes_SelectCore(o)
        table   = o.from.name
        serials = @connection.serial_columns(table)

        o.projections.map! do |x|
          if x.is_a? Arel::SqlLiteral
            if x.match("1") or x.match(table)
              x
            elsif serial = serials.find { |s| s.name == x }
              klass = ::Intersys::Serial::TableMap.get_class(serial.sql_type)
              prefix = "#{table}.#{serial.name.camelize}"
              sql = klass.attributes.map { |a| "#{prefix}_#{a.intersys_name}" }.join(", ")
              Arel::SqlLiteral.new(sql)
            else
              Arel::SqlLiteral.new("#{table}.#{x.camelize}")
            end
          else
            x
          end
        end

        super
      end

      def visit_Arel_Attributes_Attribute(o)
        super.camelize
      end

      def visit_Arel_Nodes_UnqualifiedColumn(o)
        super.camelize
      end
    end
  end
end

Arel::Visitors::VISITORS["intersys"] = Arel::Visitors::Intersys
