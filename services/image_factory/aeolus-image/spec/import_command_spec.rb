require 'spec_helper'
require 'stringio'

module Aeolus
  module Image
    describe ImportCommand do
      before(:each) do
        @stdout_orig = $stdout
        $stdout = StringIO.new
        @options = {}
        @options[:id] = "ami-test"
        @options[:target] = "ec2"
        @options[:provider] = "ec2-us-east-1"
      end

      after(:each) do
        $stdout = @stdout_orig
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