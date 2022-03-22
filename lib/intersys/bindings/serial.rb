# TODO: move to activerecord
module Intersys
  module Serial
    # provides map of Serial::Object tables. Used for lookup.
    # key is table name and value is mapped class name
    module TableMap
      def self.add(table_name, class_name)
        @@tables ||= {}
        @@tables[table_name] = class_name
      end

      def self.remove(table_name)
        @@tables.delete(table_name)
        @@tables
      end

      # returns the class name for a given table name
      def self.get_name(table_name)
        @@tables[table_name]
      end

      def self.get_class(table_name)
        get_name(table_name).constantize
      end

      def self.include?(table_name)
        @@tables.include?(table_name)
      end
    end

    class Attribute
      ALLOWED_TYPES = {
        "%String"    => :to_s,
        "%Boolean"   => nil,
        "%Integer"   => :to_i,
        "%TimeStamp" => :to_time,
        "%Float"     => :to_f,
        "%Date"      => :to_date
      }

      attr_accessor :intersys_name, :name, :type, :value

      # Name is passed in Caché-style, stored in @intersys_name, and then
      # converted to Ruby-style and stored in @name
      def initialize(name, type, value=nil)
        @intersys_name = name.camelize
        @name = name.underscore
        @type = type
        @value = value
      end

      # Converts Caché attribute value to its corresponding Ruby type
      def typecast!
        return false if @value.blank?

        if object?
          key = @value.to_i
          begin
            @value = type.constantize.find_by_id(key)
          rescue NameError
            @value = key
          end
        elsif @type == "%Boolean"
          @value = !!(@value.to_s =~ /(true|t|yes|y|1)$/i)
        else
          @value = @value.send(ALLOWED_TYPES[type])
        end
      end

      def object?
        !ALLOWED_TYPES.keys.include?(@type)
      end
    end

    class Object
      # each time a class inherits from Serial::Object, it is added to the map
      def self.inherited(subclass)
        TableMap.add(subclass.table_name, subclass.name)
      end

      # when class sets table name itself, replace its old entry in the map
      def self.table_name=(name)
        TableMap.remove(@table_name)
        if name.match(ActiveRecord::Base.connection.package)
          @table_name = name
        else
          @table_name = "#{::ActiveRecord::Base.connection.package}.#{name}"
        end
        TableMap.add(@table_name, self.name)
      end

      # by default the table name is the package plus the class name
      def self.table_name
        @table_name ||= "#{::ActiveRecord::Base.connection.package}.#{self.name}"
      end

      def self.attributes
        return @attributes if defined? @attributes
        @intersys_object ||= Intersys::Object.new(true, table_name)
        @attributes = @intersys_object.intersys_attributes(:force_reload).map do |attribute|
          name = attribute.intersys_get("Name")
          type = attribute.intersys_get("Type")
          Attribute.new(name, type)
        end
      end

      attr_accessor :owner, :owner_assoc_name
      attr_reader :intersys_object

      def initialize(owner=nil, owner_assoc_name=nil)
        @owner = owner
        @owner_assoc_name = owner_assoc_name

        @intersys_object = if owner && owner_assoc_name && !owner.new_record?
          owner.intersys_object.intersys_get(owner_assoc_name.to_s.camelize)
        else
          Intersys::Object.new(false, self.class.table_name)
        end

        initialize_attributes if owner
        define_attribute_methods
      end

      # sends new serial attribute values to Caché
      def sync_attributes!
        attributes.each do |attr|
          value = send(attr.name)
          value = value.intersys_object if attr.object? && value
          @intersys_object.intersys_set(attr.intersys_name, value.blank? ? nil : value)
        end
      end

      private

      def attributes
        self.class.attributes
      end

      # sets the object's attributes from its owner's related attributes
      def initialize_attributes
        attributes.map do |attr|
          attr.value = owner.attributes["#{owner_assoc_name}_#{attr.name}"]
          attr.typecast!
          instance_variable_set "@#{attr.name}", attr.value
        end
      end

      def define_attribute_methods
        attributes.each do |attr|
          name = attr.name
          self.class_eval "def #{name}; @#{name}; end" unless respond_to?(name)

          if respond_to?("#{name}=")
            self.class_eval "alias :overrited_#{name}= :#{name}=; def #{name}=(new_value); owner_changed!; overrited_#{name}(new_value); end", __FILE__, __LINE__
          else
            self.class_eval "def #{name}=(new_value); owner_changed!; @#{name} = new_value; end", __FILE__, __LINE__
          end
        end
      end

      def owner_changed!
        owner.send("#{owner_assoc_name}_will_change!") if owner
      end
    end
  end
end
