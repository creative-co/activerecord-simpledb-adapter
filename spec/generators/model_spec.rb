require 'spec_helper'
require 'rails'
require 'rails/generators'
require 'generators/active_record/model/model_generator'
require 'genspec'
describe :model do
  context "with no arguments or options" do
    it "should generate a help message" do
      subject.should output(/Usage/)
    end
  end

  context "with a name argument" do
    with_args :person, "name:string", "year:integer"

    it "should generate a Person model" do
      subject.should generate("app/models/person.rb")
    end
  end
end
