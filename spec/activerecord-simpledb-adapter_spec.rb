require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "model with active_record_simple_db" do

  before :each do
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end
  #test .new
  it "should be without id, created_at and updated_at when model is new" do
    p = Person.new
    p.id.should be_nil
    p.created_at.should be_nil
    p.updated_at.should be_nil
  end

  #test .create and .save
  it "should be with id, created_at and updated_at when saved when new model was saved or created immediately" do
    p1 = Person.new
    p1.save
    p1.id.should_not be_nil
    p1.created_at.should_not be_nil
    p1.updated_at.should_not be_nil
    p2 = Person.create!
    p2.id.should_not be_nil
    p2.created_at.should_not be_nil
    p2.updated_at.should_not be_nil
  end

  #test correct saving/loading properties
  it "should correct save and load all properties" do
    p = Person.create!(Person.valid_params)

    r = Person.find p.id
    Person.valid_params.each do |key, value|
      r.try(key).should == value
    end
  end

  #test validates instructions
  it "should be correct work with validates instruction" do
    class PersonWithValidates < Person
      validates_presence_of :login
      validates_uniqueness_of :login
    end

    lambda {
      PersonWithValidates.create!
    }.should raise_error(ActiveRecord::RecordInvalid, "Validation failed: Login can't be blank")

    PersonWithValidates.create!(Person.valid_params)

    lambda {
      PersonWithValidates.create!(Person.valid_params)
    }.should raise_error(ActiveRecord::RecordInvalid, "Validation failed: Login has already been taken")
  end

  #test .create
  it "should be different ids for different model instances" do
    p1 = Person.create!
    p2 = Person.create!
    p1.id.should_not == p2.id
  end

  #test .find
  it "should be found entry by id" do
    p1 = Person.create!
    p2 = Person.find p1.id
    p1.should == p2
  end

  #test .all
  it "should return collection of models when invoke .all" do
    p = Person.new
    p.save
    r = Person.all
    r.should_not be_nil
    r.should_not be_empty
  end

  #test .first
  it "should return valid entry when invoke .first" do
    p = Person.new
    p.save
    p1 = Person.first
    p1.should_not be_nil
  end

  #test .first
  it "should return valid entry when invoke .last" do
    p = Person.new
    p.save
    p1 = Person.last
    p1.should_not be_nil
  end

  #test .touch
  it "should update updated_at property when invoke .touch" do
    p1 = Person.new
    p1.save
    p2 = Person.find p1.id
    p1.touch
    p1.updated_at.should > p2.updated_at
  end

  #test .destroy
  it "should be destroy entry when invoke destroy" do
    p1 = Person.new
    p1.save
    id = p1.id
    p1.destroy
    p2 = Person.find_by_id id
    p2.should be_nil
  end

  #test optimistic locking
  it "should be throw exception when invoke destroy twice for same object" do
    p1 = Person.new
    p1.save
    p2 = Person.find p1.id
    p1.year = 2008
    p1.save
    lambda {p2.destroy}.should raise_error(ActiveRecord::StaleObjectError)
  end

  #test where selection
  it "should be correct work with where statment with equalities" do
    p1 = Person.new
    p1.year = 2008
    p1.save
    p2 = Person.new
    p2.year = 2010
    p2.save
    p = Person.where(:year => 2010).all
    p.should_not be_empty
  end
end
