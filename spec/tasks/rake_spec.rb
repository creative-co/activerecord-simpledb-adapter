require 'spec_helper'
require 'rake'

#create mock Rails
class ::Rails 
  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.env
    "development"
  end

  def self.root
    File.dirname(__FILE__) + "/../assets"
  end
end

describe "gem rake tasks" do
  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require "tasks/simpledb"
    Rake::Task.define_task(:environment)
    ActiveRecord::Base.stub!(:configurations).and_return({"development" => CONNECTION_PARAMS})
  end

  shared_examples_for "all rake tasks" do
  end

  def self.for_task task_name, &block
    describe "rake #{task_name}" do
      it "should have 'environment' as a prereq" do
        @rake[task_name].prerequisites.should include("environment")
      end

      block.call task_name
    end
  end

  for_task "db:create" do |task_name|
    it "should create sdb domain" do
      @rake[task_name].invoke
      ActiveRecord::Base.connection.list_domains.should include(CONNECTION_PARAMS[:domain_name])
    end
  end

  for_task "db:seed" do |task_name|
    before do
      ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
      ActiveRecord::Base.connection.delete_domain(CONNECTION_PARAMS[:domain_name])
      ActiveRecord::Base.connection.create_domain(CONNECTION_PARAMS[:domain_name])
    end
    it "should pushing data to sdb domain" do
      @rake[task_name].invoke
      Person.count.should == 1
    end
  end
end
