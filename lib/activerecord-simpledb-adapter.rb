module ActiveRecordSimpledbAdapter
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/simpledb.rake'
    end

    generators do
      require 'rails/generators/active_record/model/model_generator'
    end

    ActiveSupport.on_load(:active_record) do
      require 'active_record/connection_adapters/simpledb_adapter'
      require 'arel/visitors/simpledb'
    end
  end
end
