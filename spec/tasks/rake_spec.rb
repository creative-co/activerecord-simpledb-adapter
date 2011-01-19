require 'spec_helper'
require 'rake'

DOMAIN = CONNECTION_PARAMS[:domain_name]

def delete_domain_if_exist
  ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
  con = ActiveRecord::Base.connection
  con.delete_domain(DOMAIN) if con.list_domains.include? DOMAIN
end

def recreate_domain
  delete_domain_if_exist
  ActiveRecord::Base.connection.create_domain DOMAIN
end

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

  describe "db:create" do
    before do
      @task_name = "db:create"
      delete_domain_if_exist
    end
    it "should create sdb domain" do
      @rake[@task_name].invoke
      ActiveRecord::Base.connection.list_domains.should include(DOMAIN)
    end
  end

  describe "db:seed" do
    before do
      @task_name = "db:seed"
      recreate_domain
    end
    it "should pushing data to sdb domain" do
      @rake[@task_name].invoke
      Person.count.should == 1
    end
  end
  
  describe "db:collection:clear" do
    before do
      @task_name = "db:collection:clear"
      recreate_domain
      Person.create!(Person.valid_params)
    end

    it "should receive param with name \"name\"" do
      @rake[@task_name].arg_names.should include(:name)
    end

    it "should receive param with name \"ccn\"" do
      @rake[@task_name].arg_names.should include(:ccn)
    end
    it "should clear collection by name" do
      @rake[@task_name].invoke("people")
      Person.count.should == 0
    end
  end
end
