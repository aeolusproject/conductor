require 'spec_helper'

module Aeolus
  module Image
    describe ImportCommand do
      before(:each) do
        @options[:id] = "ami-test"
        @options[:target] = "ec2"
        @options[:provider] = "ec2-us-east-1"
      end

      describe "#import_image" do
        it "should import an image with default description values" do
          importc = ImportCommand.new(@options)
          begin
            importc.import_image
          rescue SystemExit => e
            e.status.should == 0
          end
          $stdout.string.should include("Image:")
          $stdout.string.should include("Target Image:")
          $stdout.string.should include("Build:")
          $stdout.string.should include("Provider Image:")
        end

        it "should import an image with file description" do
          @options[:description]  = 'spec/sample_data/image_description.xml'
          importc = ImportCommand.new(@options)
          begin
            importc.import_image
          rescue SystemExit => e
            e.status.should == 0
          end
          $stdout.string.should include("Image:")
          $stdout.string.should include("Target Image:")
          $stdout.string.should include("Build:")
          $stdout.string.should include("Provider Image:")
          #TODO: Add test to check that file was uploaded properly (when we have implemented a show/view image command)
        end
      end
    end
  end
end