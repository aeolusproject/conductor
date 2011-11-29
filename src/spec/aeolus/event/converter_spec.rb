require 'event_spec_helper'

module Aeolus
  module Event
    describe Converter do

      describe "#transform" do

        before(:each) do
          @c = Converter.new
          event = Aeolus::Event::Cidr.new({:owner=>'fred', :hardware_profile => 'm1.large'})
          @res = @c.transform(event)
        end

        it "should return true" do
          @res.should be_true
        end

        it "should set output string to passed in event attributes" do
          @c.formatted_msg.should_not be_nil
        end

        it "should wrap multiword values in quotes" do
          @c.formatted_msg.include?("\"User Initiated\"").should be_true
        end

        it "should not wrap simple values in quotes" do
          @c.formatted_msg.include?("owner=fred").should be_true
          @c.formatted_msg.include?("\"owner=fred\"").should be_false
        end
      end

      describe "#emit" do

        before(:each) do
          @output = double('output')
          @c = Converter.new(@output)
          event = Aeolus::Event::Cidr.new({:owner=>'fred', :hardware_profile => 'm1.large'})
          @c.transform(event)
        end

        it "should print the formatted message to STDOUT" do
          @output.should_receive(:puts).with(@c.formatted_msg).once
          @c.emit
        end
      end
    end
  end
end
