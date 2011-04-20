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
end
