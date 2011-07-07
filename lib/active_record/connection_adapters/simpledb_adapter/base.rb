require 'aws'
module ActiveRecord
  class Base
    def self.simpledb_connection(config) # :nodoc:

      config = config.symbolize_keys

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

    def self.batch &block
      connection.begin_batch
      block.call
      connection.commit_batch
    end

    #disable quoting for id
    def quoted_id
      id
    end
  end
end
