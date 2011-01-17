require 'spec_helper'

describe "SimpleDBAdapter ActiveRecord with optimistic locking" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should be have not nil lock version value after save" do
    p = Person.new
    p.save
    p.reload
    p.lock_version.should_not be_nil
  end

  it "should change lock version value after sevarals saves" do
    p = Person.new
    p.save
    old_lock_version = p.lock_version
    p.login = "blabla"
    p.save
    p.reload
    p.lock_version.should_not == old_lock_version
  end

  it "should raise error when tried save model with non-actual values (changed another place and time)" do
    p = Person.new
    p.save
    p1 = Person.find p.id
    p1.login = "blabla"
    p.login = "bla"
    p1.save
    lambda {p.save!}.should raise_error(ActiveRecord::StaleObjectError)
  end

  it "should raise error when tried destroy item with changed state" do
    p = Person.new
    p.save
    p1 = Person.find p.id
    p1.login = "blabla"
    p1.save
    lambda {p.destroy}.should raise_error(ActiveRecord::StaleObjectError)
  end
end
