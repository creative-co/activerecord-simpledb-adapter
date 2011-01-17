require 'spec_helper'

describe "SimpleDBAdapter establish connection" do

  it "should connect to database" do
    ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
    ActiveRecord::Base.connection.should_not be_nil
    ActiveRecord::Base.connection.class.should == ActiveRecord::ConnectionAdapters::SimpleDBAdapter
  end

  it "should be active after connection to database" do
    ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
    ActiveRecord::Base.connection.should be_active
  end

  it "should not be active after disconnection to database" do
    ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
    ActiveRecord::Base.connection.disconnect!
    ActiveRecord::Base.connection.should_not be_active
  end

  it "should be active after reconnection to database" do
    ActiveRecord::Base.establish_connection(CONNECTION_PARAMS)
    ActiveRecord::Base.connection.reconnect!
    ActiveRecord::Base.connection.should be_active
  end
  
end
