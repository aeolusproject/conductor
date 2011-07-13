require 'spec_helper'

module Aeolus
  module Image
    describe BuildCommand do
      before(:each) do
        @options[:target] = ['mock','ec2']
        @options[:template] = "#{File.dirname(__FILE__)}" + "/../examples/custom_repo.tdl"
      end

      describe "#run" do
        it "should kick off a build with valid options" do
          b = BuildCommand.new(@options, @output)
          begin
            b.run
          rescue SystemExit => e
            e.status.should == 0
          end
          $stdout.string.should include("Image:")
          $stdout.string.should include("Target Image:")
          $stdout.string.should include("Build:")
        end
        it "should exit with a message if only image id is provided" do
          @options.delete(:template)
          @options.delete(:target)
          @options[:image] = '825c94d1-1353-48ca-87b9-36f02e069a8d'
          b = BuildCommand.new(@options, @output)
          begin
            b.run
          rescue SystemExit => e
            e.status.should == 1
          end
          $stdout.string.should include("This combination of parameters is not currently supported")
        end
        it "should exit with appropriate message when a non compliant template is given" do
          @options[:template] = "spec/fixtures/invalid_template.tdl"
          @options[:image] = '825c94d1-1353-48ca-87b9-36f02e069a8d'
          b = BuildCommand.new(@options, @output)
          begin
            b.run
          rescue SystemExit => e
            e.status.should == 1
          end
          $stdout.string.should include("ERROR: The given Template does not conform to the TDL Schema")
        end
      end

      describe "#combo_implemented?" do
        it "should give useful feedback if no template or target is specified" do
          @options[:template] = ''
          @options[:target] = []
          b = BuildCommand.new(@options, @output)
          begin
            b.combo_implemented?
          rescue SystemExit => e
            e.status.should == 1
          end
          $stdout.string.should include("This combination of parameters is not currently supported")
        end
      end
    end
  end
end