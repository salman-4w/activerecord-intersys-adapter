class ActiveRecord::Base
  # create or access native Intersys object
  def intersys_object
    return @intersys_object if defined? @intersys_object

    # TODO: add smart switching between readonly & fully functional Intersys object
    @intersys_object = if new_record?
      Intersys::Object.new(false, self.class.table_name)
    else
      Intersys::Object.open(id, self.class.table_name)
    end
  end

  private

  class << self
    # Returns an array of stream column objects for the table associated with this class.
    def stream_columns
      @stream_columns ||= connection.stream_columns(table_name, "#{name} Stream Columns")
    end

    def serial_columns
      @serial_columns ||= connection.serial_columns(table_name)
    end

    private
    # Guesses the table name, but does not decorate it with prefix and suffix information.
    def undecorated_table_name(class_name = base_class.name)
      table_name = class_name.to_s.demodulize.camelize
      table_name = table_name.pluralize if pluralize_table_names
      table_name = "#{connection.package}.#{table_name}"
      table_name
    end
  end
end
