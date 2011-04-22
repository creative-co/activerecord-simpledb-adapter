require 'spec_helper'
#testes
describe "SimpleDBAdapter ActiveRecord offset operation" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
    50.times { |i| Person.create!({:login => "login#{i}"}) }
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should work" do
    Person.limit(10).offset(20).all.each_with_index do |person, i|
      person.login.should == "login#{i + 20}"
    end
  end
end 
