module Intersys

  module Callable
    STREAM_DATABASE_TYPES = ['%Stream', '%BinaryStream', '%GlobalBinaryStream', '%Stream.GlobalBinary',
                             '%CharacterStream', '%GlobalCharacterStream', '%Stream.GlobalCharacter',
                             '%Library.GlobalCharacterStream', '%Library.GlobalBinaryStream'].freeze

    def metadata_cache_was_dirty!
      %w{ reflector methods method_names properties property_names relations relation_names
        bt_relations bt_relation_names hm_relations hm_relation_names
        attributes attribute_names stream_attributes stream_attribute_names transient_attributes transient_attribute_names
    }.each do |name|
        Intersys::Object.instance_variable_set("@#{name}", {})
      end
    end

    # Returns ClassDefinition object for current class
    def intersys_reflector(force_reload = false)
      intersys_memoized(force_reload, 'reflector') { Intersys::Reflection::ClassDefinition.open(class_name) }
    end

    # returns list of methods for this class
    def intersys_methods(force_reload = false)
      intersys_memoized(force_reload, 'methods') { intersys_reflector(force_reload)._methods.to_a }
    end

    def intersys_method_names(force_reload = false)
      intersys_memoized force_reload, 'method_names' do
        intersys_methods(force_reload).map { |method| method.intersys_get('Name').underscore }
      end
    end

    # returns list of properties for current class
    def intersys_properties(force_reload = false)
      intersys_memoized(force_reload, 'properties') { intersys_reflector(force_reload).properties.to_a }
    end

    def intersys_property_names(force_reload = false)
      intersys_memoized force_reload, 'property_names' do
        intersys_properties(force_reload).map { |prop| prop.intersys_get('Name').underscore }
      end
    end

    def intersys_relations(force_reload = false)
      intersys_memoized force_reload, '' do
        intersys_properties(force_reload).find_all { |prop| prop.relationship }
      end
    end

    def intersys_relation_names(force_reload = false)
      intersys_memoized force_reload, 'relation_names' do
        intersys_relations(force_reload).map { |prop| prop.intersys_get('Name').underscore }
      end
    end

    def intersys_belongs_to_relations(force_reload = false)
      intersys_memoized force_reload, 'bt_relations' do
        bt_cardinalities = %w{ one parent }
        intersys_relations(force_reload).find_all { |prop| bt_cardinalities.include?(prop.cardinality) }
      end
    end

    def intersys_belongs_to_relation_names(force_reload = false)
      intersys_memoized force_reload, 'bt_relation_names' do
        intersys_belongs_to_relations(force_reload).map { |prop| prop.intersys_get('Name').underscore }
      end
    end

    def intersys_has_many_relations(force_reload = false)
      intersys_memoized force_reload, 'hm_relations' do
        hm_cardinalities = %w{ many children }
        intersys_relations(force_reload).find_all { |prop| hm_cardinalities.include?(prop.cardinality) }
      end
    end

    def intersys_has_many_relation_names(force_reload = false)
      intersys_memoized force_reload, 'hm_relation_names' do
        intersys_has_many_relations(force_reload).map { |prop| prop.intersys_get('Name').underscore }
      end
    end

    def intersys_attributes(force_reload = false)
      intersys_memoized force_reload, 'attributes' do
        intersys_properties(force_reload).find_all { |prop| !prop.relationship }
      end
    end

    def intersys_attribute_names(force_reload = false)
      intersys_memoized force_reload, 'attribute_names' do
        intersys_attributes(force_reload).map { |prop| prop.intersys_get('Name').underscore }
      end
    end

    def intersys_stream_attributes(force_reload = false)
      intersys_memoized force_reload, 'stream_attributes' do
        intersys_attributes(force_reload).find_all { |prop| STREAM_DATABASE_TYPES.include?(prop.intersys_get('Type')) }
      end
    end

    def intersys_stream_attribute_names(force_reload = false)
      intersys_memoized force_reload, 'stream_attribute_names' do
        intersys_stream_attributes(force_reload).map { |prop| prop.intersys_get('Name').underscore }
      end
    end

    def intersys_transient_attributes(force_reload = false)
      intersys_memoized force_reload, '' do
        intersys_properties(force_reload).find_all { |prop| prop.intersys_get('Transient') }
      end
    end

    def intersys_transient_attribute_names(force_reload = false)
      intersys_memoized force_reload, 'transient_attribute_names' do
        intersys_transient_attributes(force_reload).map { |prop| prop.intersys_get('Name').underscore }
      end
    end

    # call class method
    def intersys_call(method_name, *args)
      intersys_method(method_name).call!(args)
    end
    alias :call :intersys_call

    def intersys_has_property?(property)
      intersys_property_names.include?(property.to_s)
    end

    def intersys_has_method?(method)
      intersys_method_names.include?(method.to_s)
    end

    # Get the specified property
    def intersys_get(property)
      intersys_property(property).get
    end

    # Set the specified property
    def intersys_set(property, value)
      intersys_property(property).set(value)
    end

    def method_missing(method, *args)
      method_name = method.to_s.camelize

      if match_data = method_name.match(/(\w+)=/)
        return intersys_set(match_data.captures.first, args.first)
      end
      return intersys_get(method_name) if intersys_has_property?(method) && args.empty?
      begin
        return intersys_call(method_name, *args)
      rescue NoMethodError => e
      end
      begin
        return intersys_call("%"+method_name, *args)
      rescue NoMethodError => e
      end
      super(method, *args)
    end

    protected
    def intersys_memoized(force_reload, instance_var, &block)
      instance_val = Intersys::Object.common_get_or_set("@#{instance_var}", {})
      if !instance_val[class_name] || force_reload
        instance_val[class_name] = block.call
      end
      instance_val[class_name]
    end

    # Loads property definition with required name for required object
    # for internal use only
    def intersys_property(name)
      Property.new(database, class_name, name.to_s, self)
    end

    # Loads method definition with required name for required object
    # for internal use only
    def intersys_method(name)
      Method.new(database, class_name, name.to_s, self)
    end
  end


  class Object
    include Callable
  end
  Intersys::Object.extend(Callable)

end
