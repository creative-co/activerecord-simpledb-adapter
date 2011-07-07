module ActiveRecord
  module ConnectionAdapters
    class SimpleDBColumn < Column
      # include qouting for correct converting date to sdb
      include Quoting

      DEFAULT_NUMBER_LIMIT = 4
      DEFAULT_FLOAT_PRECISION = 4

      def initialize(name, type, limit = nil, pricision = nil, to = nil, default = nil)
        super name, nil, type, true
        @limit = limit if limit.present?
        @precision = precision if precision.present?
        @default = default
        @to = to
      end

      #convert to sdb
      def convert value
        return nil if value.nil?
        case sql_type
          when :float then
            sprintf("%.#{number_precision}f", number_shift + value.to_f)
          when :integer then
            (number_shift + value.to_i).to_s
          when :json then
            ActiveSupport::JSON.encode(value)
          else
            if value.acts_like?(:date) || value.acts_like?(:time)
              quoted_date(value)
            else
              value.to_s
            end
        end
      end

      #unconvert to sdb
      def unconvert value
        return nil if value.nil?
        case sql_type
          when :integer then
            value.to_i - number_shift
          when :float then
            precision_part = 10 ** number_precision
            ((value.to_f - number_shift) * precision_part).round / precision_part.to_f
          when :json then
            ActiveSupport::JSON.decode(value)
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
  end
end
