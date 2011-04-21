module ActiveRecord
  module ConnectionAdapters
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

      def translate_exception(exception, message)
        raise exception
      end
      # Executes the update statement and returns the number of rows affected.
      def update_sql(sql, name = nil)
        begin
          execute(sql, name)
          1
        rescue Aws::AwsError => ex
          #if not a conflict state this raise
          raise ex if ex.http_code.to_i != 409
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

