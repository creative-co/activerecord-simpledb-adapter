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

      def quote(value, column = nil)
        if value.nil?
          quote(nil_representation, column)
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
      #======== BATCHES ==========
      def begin_batch
        raise ActiveRecord::ActiveRecordError.new("Batch already started. Finish it before start new batch") \
          if batch_started

        @batch_started = true
      end

      def commit_batch type = nil
        count = batch_pool.inject(0) {|sum, (key, value)| sum += value.count }
        clear_batch and return unless count

        log({:count => count }.inspect, "SimpleDB Batch Operation") do
          pool = batch_pool[:update] || []
          @connection.batch_put_attributes(domain_name, pool) \
            if pool.any? && (type.nil? || type == :update)

          pool = batch_pool[:delete] || []
          @connection.batch_delete_attributes(domain_name, pool) \
            if pool.any? && (type.nil? || type == :delete)

          clear_batch type
        end
      end

      def clear_batch type = nil
        if type.nil?
          batch_pool.clear
          @batch_started = false
        else
          batch_pool[type].clear
        end
      end

      #===========================
      attr_reader :domain_name
      attr_reader :batch_started

      def initialize(connection, logger, aws_key, aws_secret, domain_name, connection_parameters, config)
        super(connection, logger)
        @config = config
        @batch_started = false
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
        log_title = "SimpleDB (#{sql[:action]})"
        log_title += " *BATCHED*" if batch_started
        log sql.inspect, log_title do
          case sql[:action]
          when :insert
            item_name = get_id sql[:attrs]
            item_name = sql[:attrs][:id] = generate_id unless item_name
            if batch_started
              add_to_batch :update, item_name, sql[:attrs], true
            else
              @connection.put_attributes domain_name, item_name, sql[:attrs], true
            end
            @last_insert_id = item_name
          when :update
            item_name = get_id sql[:wheres], true
            if batch_started
              add_to_batch :update, item_name, sql[:attrs], true
            else
              @connection.put_attributes domain_name, item_name, sql[:attrs], true, sql[:wheres]
            end
          when :delete
            item_name = get_id sql[:wheres], true
            if batch_started
              add_to_batch :delete, item_name
            else
              @connection.delete_attributes domain_name, item_name, nil, sql[:wheres]
            end
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
          response = nil
          if sql.offset
            first_query = sql.gsub(/LIMIT\s+\d+/, "LIMIT #{sql.offset}")
            first_query.gsub!(/SELECT(.+?)FROM/, "SELECT COUNT(*) FROM")
            log first_query, "SimpleDB (offset partial)" do
              response = @connection.select(first_query, nil, false)
            end
            response = @connection.select(sql, response[:next_token], false)
          else
            response = @connection.select(sql, nil, true)
          end
          collection_name = get_collection_column_and_name(sql)
          columns = columns_definition(collection_name)

          response[:items].each do |item|
            item.each do |id, attrs|
              ritem = {}
              ritem['id'] = id unless id == 'Domain' && attrs['Count'] # unless count(*) result
              attrs.each {|k, vs|
                column = columns[k]
                if column.present?
                  ritem[column.name] = column.unconvert(vs.first)
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
        clear_batch
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

      MAX_BATCH_ITEM_COUNT = 25
      def batch_pool
        @batch_pool ||= {}
      end

      def add_to_batch type, item_name, attributes = nil, replace = nil
        type_batch_pool = (batch_pool[type] ||= [])
        type_batch_pool << Aws::SdbInterface::Item.new(item_name, attributes, replace)
        if type_batch_pool.count == MAX_BATCH_ITEM_COUNT
          commit_batch type
        end
      end
    end
  end
end

