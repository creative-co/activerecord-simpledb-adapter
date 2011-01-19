require 'active_record/connection_adapters/abstract_adapter'
require 'active_support/core_ext/kernel/requires'
require 'active_support/core_ext/hash'
require 'uuidtools'

class Aws::SdbInterface
  def put_attributes(domain_name, item_name, attributes, replace = false, expected_attributes = {})
    params = params_with_attributes(domain_name, item_name, attributes, replace, expected_attributes)
    link = generate_request("PutAttributes", params)
    request_info( link, QSdbSimpleParser.new )
  rescue Exception
    on_exception
  end

  def delete_attributes(domain_name, item_name, attributes = nil, expected_attributes = {})
    params = params_with_attributes(domain_name, item_name, attributes, false, expected_attributes)
    link = generate_request("DeleteAttributes", params)
    request_info( link, QSdbSimpleParser.new )
  rescue Exception
    on_exception
  end

  private
  def pack_expected_attributes(attributes) #:nodoc:
    {}.tap do |result|
      idx = 0
      attributes.each do |attribute, value|
        v = value.is_a?(Array) ? value.first : value
        result["Expected.#{idx}.Name"]  = attribute.to_s
        result["Expected.#{idx}.Value"] = ruby_to_sdb(v)
        idx += 1
      end
    end
  end

  def pack_attributes(attributes = {}, replace = false, key_prefix = "")
    {}.tap do |result|
      idx = 0
      if attributes
        attributes.each do |attribute, value|
          v = value.is_a?(Array) ? value.first : value
          result["#{key_prefix}Attribute.#{idx}.Replace"] = 'true' if replace
          result["#{key_prefix}Attribute.#{idx}.Name"] = attribute
          result["#{key_prefix}Attribute.#{idx}.Value"] = ruby_to_sdb(v)
          idx += 1
        end
      end
    end
  end

  def params_with_attributes(domain_name, item_name, attributes, replace, expected_attrubutes)
    {}.tap do |p|
      p['DomainName'] = domain_name
      p['ItemName'] = item_name
      p.merge!(pack_attributes(attributes, replace)).merge!(pack_expected_attributes(expected_attrubutes))
    end
  end
end

module ActiveRecord

  class SimpleDBLogger
    def initialize(logger)
      @logger = logger
    end

    def info *args
      #skip noisy info messages from aws interface
    end

    def method_missing m, *args
      @logger.send(m, args)
    end

  end

  class Base
    def self.simpledb_connection(config) # :nodoc:
      require 'aws'

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



  end

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
        @columns << SimpleDBColumn.new(name.to_s, type.to_sym, options[:limit], options[:precision], options[:to])
        self
      end

    end

    class SimpleDBColumn < Column

      DEFAULT_NUMBER_LIMIT = 4
      DEFAULT_FLOAT_PRECISION = 4

      def initialize(name, type, limit = nil, pricision = nil, to = nil)
        super name, nil, type, true
        @limit = limit if limit.present?
        @precision = precision if precision.present?
        @to = to
      end

      def quote_number value
        case sql_type
          when :float then
            sprintf("%.#{number_precision}f", number_shift + value.to_f)
          else
            (number_shift + value.to_i).to_s
        end
      end

      def unquote_number value
        return nil if value.nil?

        case sql_type
          when :integer then
            value.to_i - number_shift
          when :float then
            precision_part = 10 ** number_precision
            ((value.to_f - number_shift) * precision_part).round / precision_part.to_f
          else
            value
        end
      end

      def db_column_name
        @to || name
      end

      private
      def number_shift
        5 * 10 ** (limit || DEFAULT_NUMBER_LIMIT)
      end

      def number_precision
        @precision || DEFAULT_FLOAT_PRECISION
      end

      def simplified_type(field_type)
        t = field_type.to_s
        if t == "primary_key"
          :string
        else
          super(t)
        end
      end
    end

    class SimpleDBAdapter < AbstractAdapter

      @@collections = {}
      @@ccn = {}

      def self.set_collection_columns table_name, columns_definition
        @@collections[table_name] = columns_definition
        @@ccn[table_name] = columns_definition.collection_column_name
      end

      def columns_definition table_name
        @@collections[table_name]
      end

      def collection_column_name table_name
        @@ccn[table_name]
      end

      ADAPTER_NAME = 'SimpleDB'.freeze

      def adapter_name
        ADAPTER_NAME
      end

      NIL_REPRESENTATION = "Aws::Nil".freeze

      def nil_representation
        NIL_REPRESENTATION
      end


      def supports_count_distinct?; false; end

      #========= QUOTING =====================

      #dirty hack for removing all (') from value for hash table attrubutes
      def hash_value_quote(value, column = nil)
        return nil if value.nil?
        quote(value, column).gsub /^'*|'*$/, ''
      end

      def quote(value, column = nil)
        if value.present? && column.present? && column.number?
          "'#{column.quote_number value}'"
        elsif value.nil?
          "'#{nil_representation}'"
        else
          super
        end
      end

      def quote_column_name(column_name)
        "`#{column_name}`"
      end
      
      def quote_table_name(table_name)
        table_name
      end
      #=======================================

      attr_reader :domain_name

      def initialize(connection, logger, aws_key, aws_secret, domain_name, connection_parameters, config)
        super(connection, logger)
        @config = config
        @domain_name = domain_name
        @connection_parameters = [
            aws_key,
            aws_secret,
            connection_parameters.merge(:nil_representation => nil_representation)
        ]
        connect
      end

      def connect
        @connection = Aws::SdbInterface.new *@connection_parameters
      end

      def tables
        @@collections.keys
      end

      def columns table_name, name = nil
        @@collections[table_name].columns
      end

      def primary_key _
        'id'
      end

      def execute sql, name = nil, skip_logging = false
        log sql.inspect, "SimpleDB" do
          case sql[:action]
          when :insert
            item_name = get_id sql[:attrs]
            item_name = sql[:attrs][:id] = generate_id unless item_name
            @connection.put_attributes domain_name, item_name, sql[:attrs], true
            @last_insert_id = item_name
          when :update
            item_name = get_id sql[:wheres], true
            @connection.put_attributes domain_name, item_name, sql[:attrs], true, sql[:wheres]
          when :delete
            item_name = get_id sql[:wheres], true
            @connection.delete_attributes domain_name, item_name, nil, sql[:wheres]
          else
            raise "Unsupported action: #{sql[:action].inspect}"
          end
        end
      end

      def insert_sql sql, name = nil, pk = nil, id_value = nil, sequence_name = nil
        super || @last_insert_id
      end
      alias :create :insert_sql

      def select sql, name = nil
        log sql, "SimpleDB" do
          result = []
          response = @connection.select(sql, nil, true)
          collection_name = get_collection_column_and_name(sql)
          columns = columns_definition(collection_name)

          response[:items].each do |item|
            item.each do |id, attrs|
              ritem = {}
              ritem['id'] = id unless id == 'Domain' && attrs['Count'] # unless count(*) result
              attrs.each {|k, vs|
                column = columns[k]
                if column.present?
                  ritem[column.name] = column.unquote_number(vs.first)
                else
                  ritem[k] = vs.first
                end
              }
              result << ritem
            end
          end
          result
        end
      end

      # Executes the update statement and returns the number of rows affected.
      def update_sql(sql, name = nil)
        begin
          execute(sql, name)
          1
        rescue Aws::AwsError => ex
          #if not conflict state raise
          raise if ex.http_code != '409'
          0
        end
      end

      # Executes the delete statement and returns the number of rows affected.
      def delete_sql(sql, name = nil)
        update_sql(sql, name)
      end

      def create_domain domain_name
        @connection.create_domain domain_name
      end

      def delete_domain domain_name
        @connection.delete_domain domain_name
      end

      def list_domains
        @connection.list_domains[:domains]
      end

      private

      def generate_id
        UUIDTools::UUID.timestamp_create().to_s
      end

      def get_id hash, delete_id = false
        if delete_id
          hash.delete(:id) || hash.delete('id')
        else
          hash[:id] || hash['id']
        end
      end

      def get_collection_column_and_name sql
        if sql.match /`?(#{@@ccn.values.join("|")})`?\s*=\s*'(.*?)'/
          $2
        else
          raise  PreparedStatementInvalid, "collection column '#{@@ccn.values.join(" or ")}' not found in the WHERE section in query"
        end
      end
    end

  end
end
