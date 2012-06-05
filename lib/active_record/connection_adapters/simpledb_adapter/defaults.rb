module ActiveRecordSimpledbAdapter
  module Defaults
    def self.included(base)
      base.send :alias_method_chain, :initialize, :defaults
    end

    def initialize_with_defaults(attrs = nil)
      initialize_without_defaults(attrs) do
        safe_attribute_names = []
        if attrs
          stringified_attrs = attrs.stringify_keys
          safe_attrs =  sanitize_for_mass_assignment(stringified_attrs)
          safe_attribute_names = safe_attrs.keys.map { |x| x.to_s }
        end

        ActiveRecord::Base.connection.columns_definition(self.class.table_name).columns_with_defaults.each do |column|
          has_default = !safe_attribute_names.any? { |attr_name| 
            attr_name =~ /^#{column.name}($|\()/ 
          }

          if has_default
            value = if column.default.is_a? Proc
                      column.default.call
                    else
                      column.default
                    end
            __send__("#{column.name}=", value)
            changed_attributes.delete(column.name)
          end
        end
        yield(self) if block_given?
      end
    end
  end
end
