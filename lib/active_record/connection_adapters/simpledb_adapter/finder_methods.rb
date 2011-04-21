module ActiveRecord
  module FinderMethods
    def exists?(id = nil)
      id = id.id if ActiveRecord::Base === id

      join_dependency = construct_join_dependency_for_association_find
      relation = construct_relation_for_association_find(join_dependency)
      relation = relation.except(:select).select("*").limit(1)

      case id
      when Array, Hash
        relation = relation.where(id)
      else
        relation = relation.where(table[primary_key.name].eq(id)) if id
      end

      connection.select_value(relation.to_sql) ? true : false
    end
  end
end
