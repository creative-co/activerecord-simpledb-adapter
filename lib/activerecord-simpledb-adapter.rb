if defined?(Rails)
  require "railtie"
else
  require 'active_record/connection_adapters/simpledb_adapter'
  require 'arel/visitors/simpledb'
end
