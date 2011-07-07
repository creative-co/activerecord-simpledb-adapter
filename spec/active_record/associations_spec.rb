require 'spec_helper'
describe "SimpleDBAdapter ActiveRecord associations" do
  class Bar < ActiveRecord::Base
    columns_definition do |t|
      t.json :bar
    end
    has_many :fars
  end
  class Far < ActiveRecord::Base
    columns_definition do |t|
      t.json :bar
      t.string :bar_id
    end
    belongs_to :bar
  end

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should create has many recources" do
    t = Bar.create!
    t.fars.create!
    t.fars.count.should == 1
  end
end
