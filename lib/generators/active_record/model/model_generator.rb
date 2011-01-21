require 'rails/generators/active_record'

module ActiveRecord
  module Generators
    class ModelGenerator < Base
      argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"

      check_class_collision

      class_option :timestamps, :type => :boolean
      class_option :parent,     :type => :string, :desc => "The parent class for the generated model"

      def create_model_file
        template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      hook_for :test_framework

      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end
      protected

        def parent_class_name
          options[:parent] || "ActiveRecord::Base"
        end

    end
  end
end
