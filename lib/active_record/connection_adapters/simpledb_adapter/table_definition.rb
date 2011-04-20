module ActiveRecord
  module ConnectionAdapters
    class SimpleDbTableDifinition < TableDefinition

      attr_reader :collection_column_name

      def initialize collection_column_name
        super nil
        @collection_column_name = collection_column_name
      end

      def xml_column_fallback(*args)
        raise ConfigurationError, "Not supported"
      end

      def [](name)
        @columns.find {|column| column.db_column_name == name.to_s}
      end

      def column(name, type, options = {})
        raise ConfigurationError, %Q(column '#{collection_column_name}' reserved, please change column name) if name.to_s == collection_column_name
        @columns << SimpleDBColumn.new(name.to_s, type.to_sym, options[:limit], options[:precision], options[:to], options[:default])
        self
      end

      def columns_with_defaults
        @columns_with_defaults ||= @columns.select { |column| column.default.present? }
      end

    end
  end
end
