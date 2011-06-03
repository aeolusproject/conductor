require 'spec_helper'

module Aeolus
  module Image
    describe ConfigParser do
      it "should parse the specified command" do
        config_parser = ConfigParser.new(%w(list))
        config_parser.process
        config_parser.command.should == 'list'
      end

      it "should notify the user of an invalid command" do
        config_parser = ConfigParser.new(%w(sparkle))
        config_parser.should_receive(:exit).with(0)
        silence_stream(STDOUT) do
          config_parser.process
        end
      end

      it "should exit gracefully with bad params" do
        begin
          silence_stream(STDOUT) do
            ConfigParser.new(%w(delete --fred)).should_receive(:exit).with(0)
          end
        rescue SystemExit => e
          e.status.should == 0
        end
      end

      it "should set options hash for valid general options" do
        config_parser = ConfigParser.new(%w(list --user joe --password cloud --images))
        config_parser.options[:user].should == 'joe'
        config_parser.options[:password].should == 'cloud'
        config_parser.options[:subcommand].should == :images
      end

      it "should set options hash for valid list options" do
        config_parser = ConfigParser.new(%w(list --builds 12345))
        config_parser.options[:subcommand].should == :builds
        config_parser.options[:id].should == '12345'
      end

      it "should set options hash for valid build options" do
        config_parser = ConfigParser.new(%w(build --target ec2,rackspace --image 12345 --template my.tmpl))
        config_parser.options[:target].should == ['ec2','rackspace']
        config_parser.options[:image].should == '12345'
        config_parser.options[:template].should == 'my.tmpl'
      end

      it "should set options hash for valid push options" do
        config_parser = ConfigParser.new(%w(push --provider ec2-us-east1 --id 12345))
        config_parser.options[:provider].should == 'ec2-us-east1'
        config_parser.options[:id].should == '12345'
      end

      it "should set options hash for valid delete options" do
        config_parser = ConfigParser.new(%w(delete --build 12345))
        config_parser.options[:build].should == '12345'
      end
    end
  end
end