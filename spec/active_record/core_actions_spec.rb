require 'spec_helper'

describe "SimpleDBAdapter ActiveRecord core actions" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
    Person.create!(Person.valid_params)
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should be correct work with .all statement" do
    Person.all.should_not be_empty
    Person.all.first.is_a?(Person).should be_true
  end

  it "should be correct work with .first statement" do
    Person.first.is_a?(Person).should be_true
  end

  it "should be correct work with .last statement" do
    Person.last.is_a?(Person).should be_true
  end

  it "should be correct work with .count statement" do
    Person.count.should > 0
  end

  it "should be correct work with .find statement" do
    p1 = Person.create!
    p2 = Person.find p1.id
    p1.should == p2
  end
  
  it "should be correct work with .destroy statement" do
    p1 = Person.new
    p1.save
    id = p1.id
    p1.destroy
    p2 = Person.find_by_id id
    p2.should be_nil
  end
end
