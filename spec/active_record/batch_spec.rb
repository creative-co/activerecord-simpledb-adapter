require 'spec_helper'
#spec helpers difition
class F < ActiveRecord::Base
  columns_definition do |t|
    t.string :body
  end

  has_many :bs
  after_save lambda { self.bs.create!({:body => "test"}) }
end
class B < ActiveRecord::Base
  columns_definition do |t|
    t.string :body
    t.string :f_id
  end
end
#testes
describe "SimpleDBAdapter ActiveRecord batches operation" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should work with usual create statments" do
    count = 5
    Person.batch do
      count.times { |i| Person.create_valid }
      Person.count.should == 0
    end
    items = Person.all
    items.count.should == count
    items.each { |item| item.is_valid? }
  end

  #this test doesn't work with fakesdb
  it "should work with usual destroy statments" do
    count = 5
    items = []
    count.times { items << Person.create_valid }
    Person.batch(:delete) do
      items.each {|item| item.destroy }
    end
    Person.count.should == 0
  end
  
  it "should auto split to several batches when count of items more than BATCH_MAX_ITEM_COUNT" do
    count = 35
    Person.batch do
      count.times { |i| Person.create_valid }
    end
    Person.count.should == count
  end

  it "should batch internal operations too (sub-updates)" do
    count = 5
    F.batch do
      count.times { F.create!({:body => "body"}) }
    end
    [F, B].each {|r| r.count.should == count }
  end
end 
