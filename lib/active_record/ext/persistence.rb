module ActiveRecord
  module Persistence
    # Public: override AR's create instance method to use intersys_object
    # because Caché won't return new object's id via SQL calls
    # Returns id of newly created object
    def create
      intersys_set_attributes(arel_attributes_values(!id.nil?))
      intersys_object.save
      self.id = intersys_object.id
      @new_record = false
      id
    end

    # Public: extend AR's update instance method to also update any changed
    # serial objects.
    def update_with_serial_objects(attribute_names = @attributes.keys)
      # punt if there are no changed serial attributes
      if (attribute_names & self.class.serial_columns.map(&:name)).empty?
        update_without_serial_objects(attribute_names)
      else
        attributes_with_values = arel_attributes_values(false, false, attribute_names)
        return 0 if attributes_with_values.empty?
        intersys_set_attributes(attributes_with_values)
        intersys_object.save
      end
    end
   # alias_method_chain :update, :serial_objects

    private

    # Sets attributes of object using native intersys object calls
    def intersys_set_attributes(attributes)
      attributes.each do |arel_attr, value|
        column = column_for_attribute(arel_attr.name)

        next if column.calculated?

        if column.serial_object?
          serial_object = self.send(column.name)
          serial_object.sync_attributes!
          intersys_object.intersys_set(column.intersys_name, serial_object.intersys_object)
        elsif column.intersys_association?
          intersys_object.intersys_call("#{column.intersys_name}SetObjectId", value)
        else
          intersys_object.intersys_set(column.intersys_name, value)
        end
      end
    end

  end
end
