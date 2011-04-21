require 'rubygems'
# Set up gems listed in the Gemfile.
gemfile = File.expand_path('../../Gemfile', __FILE__)
begin
  ENV['BUNDLE_GEMFILE'] = gemfile
  require 'bundler'
  Bundler.setup
rescue Bundler::GemNotFound => e
  STDERR.puts e.message
  STDERR.puts "Try running `bundle install`."
  exit!
end if File.exist?(gemfile)

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'ap'
require 'rspec'
require 'aws'
require 'active_record'
require 'active_record/connection_adapters/simpledb_adapter'
require 'arel/visitors/simpledb'

CONNECTION_PARAMS = {
    :adapter => 'simpledb',
    :access_key_id => "some_key",
    :secret_access_key => "some_secret",
    :domain_name => "test_domain",
    :host => 'localhost',
    :port => '8080',
    :protocol => 'http'
}

$config = CONNECTION_PARAMS

#define stub model
class Person < ActiveRecord::Base
  establish_connection $config

  columns_definition do |t|
    t.string :login
    t.integer :year, :limit => 4
    t.boolean :active
    t.string :state
    t.float :price
    t.integer :lock_version

    t.timestamps
  end

  def self.valid_params
    {
        :login => "john",
        :year => 2010,
        :active => true,
        :price => 10.04,
        :state => 'paid'
    }
  end
end


