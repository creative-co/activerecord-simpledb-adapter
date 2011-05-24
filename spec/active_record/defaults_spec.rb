require 'spec_helper'

describe "SimpleDBAdapter ActiveRecord default values for attributes" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  class ModelWithDefaults < ActiveRecord::Base
    columns_definition do |c|
      c.string :p1, :default => 'payload_string1'
      c.string :p2, :default => lambda { "payload_string2" }
      c.integer :p3, :default => 10
      c.float :p4, :default => 10.05
      c.boolean :p5, :default => true
      c.string :p6
    end
  end

  it "should correct sets after create new instance of model" do
    m = ModelWithDefaults.new
    m.p1.should == "payload_string1"
    m.p2.should == "payload_string2"
    m.p3.should == 10
    m.p4.should == 10.05
    m.p5.should be_true
    m.p6.should be_nil
  end

end
