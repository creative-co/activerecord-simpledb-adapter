require 'arel/visitors/to_sql'
module Arel
  module Visitors
    class SimpleDB < Arel::Visitors::ToSql
      private

      def hash_value_quote value, column = nil
        @connection.hash_value_quote value, column
      end

      def visit_Arel_Nodes_DeleteStatement o
        {
            :action => :delete,
            :wheres => merge_to_hash(o.wheres)
        }
      end

      def visit_Arel_Nodes_UpdateStatement o
        {
            :action => :update,
            :attrs => merge_to_hash(o.values),
            :wheres => merge_to_hash(o.wheres)
        }
      end
      
      def visit_Arel_Nodes_InsertStatement o
        collection_name = visit(o.relation)
        ccn = @connection.collection_column_name(collection_name)

        {
            :action => :insert,
            :attrs => visit(o.values).merge(ccn => collection_name)
        }
      end
    
      def visit_Arel_Nodes_SelectStatement o
        o.orders.each do |order|
          attr = visit(order).to_s.gsub(/ASC|DESC/, '').strip
          # The sort attribute must be present in predicates
          o.cores.first.wheres << SqlLiteral.new("#{attr} IS NOT NULL")
        end
        collection = o.cores.first.froms.name
        o.cores.first.wheres << SqlLiteral.new("`#{@connection.collection_column_name(collection)}` = #{quote(collection)}")
        o.cores.first.froms = Table.new @connection.domain_name
        query = super
        query.offset = o.offset.expr if o.offset 
        query.limit = o.limit.expr if o.limit 
        query
      end

      def visit_Arel_Nodes_Offset o
        nil
      end

      def visit_Arel_Nodes_Values o
        result = {}
        o.expressions.zip(o.columns).map {|value, column|
          result[column.column.db_column_name] = hash_value_quote(value, column.column)
        }
        result
      end

      def visit_Arel_Nodes_Grouping o
        visit(o.expr)
      end

      def visit_Arel_Nodes_And o
        visit(o.left).merge(visit(o.right)).tap{|m| m.override_to_s super}
      end
      
      def visit_Arel_Nodes_Assignment o
        right = o.right ? hash_value_quote(o.right, o.left.column) : nil
        left = o.left.column.name
        {left => right}
      end

      def visit_Arel_Nodes_Equality o
        right = o.right ? hash_value_quote(o.right, o.left.column) : nil
        begin
        left = o.left.column.name
        rescue
          puts $!.backtrace
        end
        {left => right}.tap { |m|
          m.override_to_s "#{visit o.left} = #{quote(o.right, o.left.column)}"
        }
      end

      def visit_Arel_Nodes_NotEqual o
        "#{visit o.left} != #{o.right.nil? ? @connection.nil_representation : visit(o.right)}"
      end
      
      def visit_Arel_Attributes_Attribute o
        # Do not use table. prefix for attribute names
        @last_column = o.column
        quote_column_name o.column.db_column_name
      end
      alias :visit_Arel_Attributes_Integer :visit_Arel_Attributes_Attribute
      alias :visit_Arel_Attributes_Float :visit_Arel_Attributes_Attribute
      alias :visit_Arel_Attributes_Decimal :visit_Arel_Attributes_Attribute
      alias :visit_Arel_Attributes_String :visit_Arel_Attributes_Attribute
      alias :visit_Arel_Attributes_Time :visit_Arel_Attributes_Attribute
      alias :visit_Arel_Attributes_Boolean :visit_Arel_Attributes_Attribute

      def visit_Arel_Nodes_SqlLiteral o
        # Strip table name from table.column -like literals
        result = o.to_s.gsub(/\w+\.([\w*]+)/, '\1')
        if result.match /`(\w+)`\s*=\s*'(.*?)'/
          # transform 'a = b' to {'a' => 'b'}
          {$1 => $2}.tap {|m| m.override_to_s result}
        else
          result
        end
      end
      alias :visit_Arel_SqlLiteral :visit_Arel_Nodes_SqlLiteral


      def merge_to_hash a
        a.map{|x| visit(x)}.inject({}, &:merge)
      end
    end

    VISITORS['simpledb'] = Arel::Visitors::SimpleDB
  end
end
class String
  attr_accessor :offset
  attr_accessor :limit
end
class Object
  def override_to_s s
    @override_to_s = s
    #noinspection RubyResolve
    def self.to_s; @override_to_s; end
  end
end
