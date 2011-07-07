require 'spec_helper'

describe "SimpleDBAdapter ActiveRecord types convertation" do
  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should correct represent nil values for all types of columns" do
    p = Person.create!
    Person.valid_params.each do |name, value|
      p.try(name).should be_nil
      p.try(name).class.should == NilClass
    end
  end
  
  it "should correct convert types from sdb to local" do
    p = Person.create!(Person.valid_params)
    p1 = Person.find p.id
    Person.valid_params.each do |name, value|
      p.try(name).should  == p1.try(name)
      p.try(name).should.class  == p1.try(name).class
    end
  end
end
