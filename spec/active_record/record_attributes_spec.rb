require 'spec_helper'

describe "SimpleDBAdapter ActiveRecord attributes" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should correct auto-generated properites (id, created_at, updated_at)" do
    p = Person.new
    p.id.should be_nil
    p.created_at.should be_nil
    p.updated_at.should be_nil
    p.save!
    p.id.should_not be_nil
    p.created_at.should_not be_nil
    p.updated_at.should_not be_nil
  end

  it "should be different ids for different model instances after create" do
    p1 = Person.create!
    p2 = Person.create!
    p1.id.should_not == p2.id
  end

  it "should correct saved and loaded" do
    p = Person.create!(Person.valid_params)

    r = Person.find p.id
    Person.valid_params.each do |key, value|
      r.try(key).should == value
    end
  end

  it "should correct save and load integer values" do
    p = Person.new
    p.year = 2010
    p.save
    p.year = p.year + 1
    p.save
    p.reload
    p.year.is_a?(Fixnum).should be_true
    p.year.should == 2011
  end

  it "should correct save and load float values" do
    p = Person.new
    p.price = 10.04
    p.save
    p.price = p.price + 1.2
    p.save
    p.reload
    p.price.is_a?(Float).should be_true
    p.price.should == 11.24
  end

  it "should corrert save and load negative values" do
    p = Person.new
    p.price = -10.04
    p.year = -200
    p.save
    p.price = p.price - 1.02
    p.year = p.year - 2
    p.save
    p.reload
    p.price.should == -11.06
    p.year.should == -202
  end

  it "should correct save and load boolean values" do
    p = Person.new
    p.active = true
    p.save
    p.reload
    p.active.should be_true
    p.active = false
    p.save
    p.reload
    p.active.should be_false
  end

  it "should correct save and load string values" do
    p = Person.new
    p.login = "superman"
    p.save
    p.login = p.login + "123"
    p.save
    p.reload
    p.login.should == "superman123"
  end
  
  it "should update updated_at property when invoke .touch" do
    p1 = Person.new
    p1.save
    p2 = Person.find p1.id
    p1.touch
    p1.updated_at.class.should == Time
    p1.updated_at.should > p2.updated_at
  end
end
