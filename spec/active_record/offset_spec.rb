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
    count, offset = 10, 20
    persons = Person.limit(count).offset(offset).all
    persons.count.should == count
    persons.each_with_index do |person, i|
      person.login.should == "login#{i + offset}"
    end
  end
end 
