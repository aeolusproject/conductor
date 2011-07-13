require 'spec_helper'

module Aeolus
  module Image
    describe BaseCommand do

      it "should determine the correct credentials for HTTP Authentication" do
        basec = BaseCommand.new
        iwhd = basec.send :iwhd
        iwhd.user.should == nil

        conductor = basec.send :conductor
        conductor.user.should == "admin"
        conductor.password.should == "password"

        basec = BaseCommand.new({:username => "testusername", :password=> "testpassword"})
        conductor = basec.send :conductor
        conductor.user.should == "testusername"
        conductor.password.should == "testpassword"
      end

      describe "#read_file" do

        it "should return nil when it cannot find file" do
          b = BaseCommand.new
          b.send(:read_file, "foo.fake").should be_nil
        end

        it "should read file content into string variable" do
          b = BaseCommand.new
          template_str = b.send(:read_file, "#{File.dirname(__FILE__)}" + "/../examples/custom_repo.tdl")
          template_str.should include("<template>")
        end
      end

      describe "#is_file?" do
        it "should return false if no file found" do
          b = BaseCommand.new
          b.send(:is_file?, "foo.fake").should be_false
        end
        it "should return true if file found" do
          b = BaseCommand.new
          valid_file = "#{File.dirname(__FILE__)}" + "/../examples/aeolus-cli"
          b.instance_eval {@config_location = valid_file}
          b.send(:is_file?, valid_file).should be_true
        end
      end

      describe "#write_file" do
        it "should write a new file" do
          b = BaseCommand.new
          new_file = "/tmp/foo.fake"
          b.instance_eval {@config_location = new_file}
          b.send(:write_file)
          conf = YAML::load(File.open(File.expand_path(new_file)))
          conf.has_key?(:iwhd).should be_true
          File.delete(new_file)
        end
      end

      describe "#validate_xml_document?" do
        it "should return errors given non compliant xml" do
          b = BaseCommand.new
          errors = b.send(:validate_xml_document, "examples/tdl.rng", File.read("spec/fixtures/invalid_template.tdl"))
          errors.length.should > 0
        end

        it "should return no errors" do
          b = BaseCommand.new
          errors = b.send(:validate_xml_document, "examples/tdl.rng", File.read("spec/fixtures/valid_template.tdl"))
          errors.length.should == 0
        end
      end
    end
  end
end