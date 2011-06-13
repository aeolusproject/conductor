require 'spec_helper'
require 'stringio'

module Aeolus
  module Image
    describe PushCommand do

      before(:each) do
        @output = double('output')
        @stdout_orig = $stdout
        $stdout = StringIO.new
        @options = {}
        @options[:provider] = ['mock']
        @options[:user] = 'admin'
        @options[:password] = 'password'
      end

      after(:each) do
        $stdout = @stdout_orig
      end

      describe "#run" do
        before(:each) do
          options = {}
          options[:target] = ['mock','ec2']
          options[:template] = 'spec/sample_data/custom_repo.tdl'
          b = BuildCommand.new(options)
          sleep(5)
          tmpl_str = b.send(:read_file, options[:template])
          b.console.build(tmpl_str, ['mock','ec2']).each do |adaptor|
            @build_id = adaptor.image
          end
          b.console.shutdown
          @options[:id] = @build_id
        end

        it "should push an image with valid options" do
          p = PushCommand.new(@options, @output)
          begin
            p.run
          rescue SystemExit => e
            e.status.should == 0
          end
          $stdout.string.should include("Image:")
          $stdout.string.should include("Provider Image:")
          $stdout.string.should include("Build:")
        end
      end

      describe "#combo_implemented?" do
        it "should give useful feedback if no template or target is specified" do
          @options[:id] = ''
          @options[:provider] = []
          b = PushCommand.new(@options, @output)
          begin
            b.combo_implemented?
          rescue SystemExit => e
            e.status.should == 1
          end
          $stdout.string.should  include("This combination of parameters is not currently supported")
        end
      end
    end
  end
end