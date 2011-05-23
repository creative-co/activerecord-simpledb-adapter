require 'aws'
module ActiveRecord
  class Base
    def self.included(base)
      puts "test"
    end
    def self.simpledb_connection(config) # :nodoc:

      config = config.symbolize_keys
      #fix this (replace to module)
      alias_method_chain :initialize, :defaults

      ConnectionAdapters::SimpleDBAdapter.new nil, logger,
          config[:access_key_id],
          config[:secret_access_key],
          config[:domain_name],
          {
              :server => config[:host],
              :port => config[:port],
              :protocol => config[:protocol],
              :connection_mode => :per_thread,
              :logger => SimpleDBLogger.new(logger)
          },
          config
    end

    DEFAULT_COLLECTION_COLUMN_NAME = "collection".freeze

    def self.columns_definition options = {}
      table_definition = ConnectionAdapters::SimpleDbTableDifinition.new(options[:collection_column_name] || DEFAULT_COLLECTION_COLUMN_NAME)
      table_definition.primary_key(Base.get_primary_key(table_name.to_s.singularize))

      
      yield table_definition if block_given?

      ConnectionAdapters::SimpleDBAdapter.set_collection_columns table_name, table_definition
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
          if !safe_attribute_names.any? { |attr_name| attr_name =~ /^#{column.name}($|\()/ }
            value =  if column.default.is_a? Proc
                       column.default.call(self)
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

    def self.batch &block
      connection.begin_batch
      block.call
      connection.commit_batch
    end
  end
end
