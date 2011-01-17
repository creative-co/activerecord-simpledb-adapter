require 'spec_helper'

describe "SimpleDBAdapter ActiveRecord where statement" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
    Person.create!(Person.valid_params)
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should be return items by conditions with different type values" do
    Person.valid_params.each do |name, value|
      result = Person.where(name => value).first
      result.try(name).should == value
    end
  end
  
  it "should be return items by condition with table name prefix" do
    result = Person.where("people.state" => 'paid').first
    result.state.should == 'paid'
  end
end
