require 'spec_helper'

describe "SimpleDBAdapter ActiveRecord validates" do

  before :each do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection($config)
    ActiveRecord::Base.connection.create_domain($config[:domain_name])
  end

  after :each do
    ActiveRecord::Base.connection.delete_domain($config[:domain_name])
  end

  it "should be correct work with validates presense of" do
    class PersonWithValidates < Person
      validates_presence_of :login
    end

    lambda {
      PersonWithValidates.create!
    }.should raise_error(ActiveRecord::RecordInvalid, "Validation failed: Login can't be blank")
  end
  
  it "should be correct work with validates uniqueness of" do
    class PersonWithValidates < Person
      validates_uniqueness_of :login
    end

    PersonWithValidates.create!(Person.valid_params)

    lambda {
      PersonWithValidates.create!(Person.valid_params)
    }.should raise_error(ActiveRecord::RecordInvalid, "Validation failed: Login has already been taken")
  end
end
