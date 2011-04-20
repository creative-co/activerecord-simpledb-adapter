module ActiveRecord
  module Validations
    class UniquenessValidator < ActiveModel::EachValidator

      def validate_each(record, attribute, value)
        finder_class = find_finder_class_for(record)
        table = finder_class.unscoped

        table_name   = record.class.quoted_table_name

        if value && record.class.serialized_attributes.key?(attribute.to_s)
          value = YAML.dump value
        end

        sql, params  = mount_sql_and_params(finder_class, table_name, attribute, value)

        relation = table.where(sql, *params)

        Array.wrap(options[:scope]).each do |scope_item|
          scope_value = record.send(scope_item)
          relation = relation.where(scope_item => scope_value)
        end

        if record.persisted?
          # TODO : This should be in Arel
          relation = relation.where("#{record.class.primary_key} != ?", record.send(:id))
        end

        if relation.exists?
          record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
        end
      end

      protected
      def mount_sql_and_params(klass, table_name, attribute, value) #:nodoc:
        column = klass.columns_hash[attribute.to_s]

        sql_attribute = "#{klass.connection.quote_column_name(column.db_column_name)}"
        sql = "#{sql_attribute} = ?"
        if value.nil?
          [sql, [value]]
        elsif (options[:case_sensitive] || !column.text?)
          [sql, [value]]
        else
          [sql, [value.downcase]]
        end
      end
    end
  end
end
