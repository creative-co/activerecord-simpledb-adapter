require 'spec_helper'
describe "SimpleDBAdapter ActiveRecord column with json type" do
  class RecordWithJson < ActiveRecord::Base
    columns_definition do |t|
      t.json :foo
    end
  end

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  def check_value val
    t = RecordWithJson.create!(:foo => val)
    t.reload
    t.foo.should == val
  end

  it "should correct convert/unconvert nil, string, int, float, array, hash values" do
    [nil, 'test', 123, 123.01, [1,2], { 'test' => 'value'}].each do |val|
      check_value val
    end
  end
end
