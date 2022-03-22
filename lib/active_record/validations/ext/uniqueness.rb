module ActiveRecord
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator
      protected

      # override default method to search column by attribute name that not equal with column name
      def mount_sql_and_params(klass, table_name, attribute, value) #:nodoc:
        column = klass.columns_hash[attribute.to_s]

        operator = if value.nil?
          "IS ?"
        elsif column.text?
          value = column.limit ? value.to_s.mb_chars[0, column.limit] : value.to_s
          "#{klass.connection.case_sensitive_equality_operator} ?"
        else
          "= ?"
        end

        sql_attribute = "#{table_name}.#{klass.connection.quote_column_name(column.name)}"

        if value.nil? || (options[:case_sensitive] || !column.text?)
          sql = "#{sql_attribute} #{operator}"
        else
          sql = "LOWER(#{sql_attribute}) = LOWER(?)"
        end

        [sql, [value]]
      end
    end
  end
end
