module ActiveRecord
  module ConnectionAdapters
    class IntersysColumn < Column
      attr_reader :intersys_name
      # Instantiates a new Intersys column definition in a table.
      # Name is passed in Caché-style, stored in @intersys_name, and then
      # converted to Ruby-style before passing it on to super
      def initialize(name, default, sql_type = nil, null = true, calculated = false, intersys_association = false, serial_object = false)
        @intersys_name = name.camelize
        @calculated = calculated
        @intersys_association = intersys_association
        @serial_object = serial_object
        super(name.underscore, default, sql_type, null)
      end

      def calculated?
        @calculated
      end

      def intersys_association?
        @intersys_association
      end

      def serial_object?
        @serial_object
      end

      # mark column as serial object
      def serial_object!
        @calculated = false
        @intersys_association = false
        @serial_object = true
      end
    end
  end
end
