module ActiveRecord
  module AttributeMethods
    module ClassMethods
      # adds generation of all the attribute related methods for streams and
      # serial objects in the database, then implements AR's method
      def define_attribute_methods
        define_stream_attribute_methods
        define_serial_attribute_methods
        # The rest of this method is directly from:
        # activerecord/lib/active_record/attribute_methods.rb#define_attribute_methods
        # Use a mutex; we don't want two thread simaltaneously trying to define
        # attribute methods.
        @attribute_methods_mutex.synchronize do
          return if attribute_methods_generated?
          superclass.define_attribute_methods unless self == base_class
          super(column_names)
          @attribute_methods_generated = true
        end
      end

      private

      # generates getter method for Intersys Stream attributes
      #
      # NOTE: the setter method will eventually be generated here as well, but
      # setting stream (obj_id) properties isn't working due to String vs Data
      # type requirements
      def define_stream_attribute_methods
        return if attribute_methods_generated?
        stream_columns.each do |column|
          method_name = column.name
          generated_attribute_methods.module_eval <<-STR, __FILE__, __LINE__ + 1
            if method_defined?(:#{method_name})
              undef :#{method_name}
            end
            def #{method_name}
              intersys_object.intersys_get "#{method_name.camelize}"
            end
          STR
        end
      end

      def define_serial_attribute_methods
        return if attribute_methods_generated?
        serial_columns.each do |column|
          next unless column.serial_object?
          method_name = column.name
          class_name  = Intersys::Serial::TableMap.get_name(column.sql_type)

          generated_attribute_methods.module_eval <<-STR, __FILE__, __LINE__ + 1
            if method_defined?(:#{method_name})
              undef :#{method_name}
            end
            def #{method_name}
              @#{method_name} ||= #{class_name}.new(self, '#{method_name}')
            end

            if method_defined?(:#{method_name}=)
              undef :#{method_name}=
            end
            def #{method_name}=(new_value)
              #{method_name}_will_change! if #{method_name} != new_value
              new_value.owner = self
              new_value.owner_assoc_name = '#{method_name}'
              @#{method_name} = new_value
            end
          STR
        end
      end
    end

    # call native intersys methods when available
    def method_missing(method, *args, &block)
      if native_intersys_method?(method)
        intersys_object.send(method, *args, &block)
      else
        super
      end
    end

    private
    def native_intersys_method?(method_id)
      intersys_object.respond_to?(method_id) || intersys_object.intersys_has_method?(method_id) || intersys_object.intersys_has_property?(method_id)
    end
  end
end
