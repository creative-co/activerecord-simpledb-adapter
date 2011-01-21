require 'spec_helper'
require 'rails'
require 'rails/generators'
require 'generators/active_record/model/model_generator'
require 'genspec'
describe :model do
  context "with a name argument" do
    with_args "foo", "name:string", "year:integer", "--orm=active_record"

    it "should generate a model called 'foo' with two columns" do
      subject.should generate("app/models/foo.rb") { |content|
        content.should =~ /class Foo < ActiveRecord\:\:Base/
        content.should =~ /columns_definition do \|c\|\n    c.string :name\n    c.integer :year\n  end/
      }
    end
  end
end
