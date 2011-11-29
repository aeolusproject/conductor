require 'event_spec_helper'

module Aeolus
  module Event
    describe Base do

      describe "#process" do
        it "should return true when an event is sent successfully" do
          event = Base.new
          converter = Aeolus::Event::Converter.new
          result = event.process(converter)
          result.should be_true
        end
        it "should call SyslogConverter as the default" do
          event = Base.new
          converter = double('converter')
          Aeolus::Event::SyslogConverter.stub!(:new).and_return(converter)
          converter.should_receive(:process).with(event).once
          event.process
        end
        it "should call specified converter object when passed in" do
          event = Base.new
          converter = Aeolus::Event::SyslogConverter.new
          converter.stub!(:process).and_return(true)
          converter.should_receive(:process).with(event).and_return(true)
          event.process(converter)
        end
      end
      describe "#attributes" do
        it "should return the attributes defined in the Base class as a single level array" do
          event = Base.new
          event.attributes.include?(:event_id).should be_true
          event.attributes.include?(:action).should be_true
        end
      end
      describe "#changed_fields" do
        it "should return empty array if no changes present" do
          event = Base.new
          result = event.changed_fields
          result.should == []
        end
        it "should return a list if changes present" do
          Base.class_eval do
            def owner
             @owner
            end
            def owner=(val)
              @owner = val
            end
          end
          event = Base.new({:owner=>'sseago',:old_values=>{:owner=>'jayg'}})
          result = event.changed_fields
          result.should == [:owner]
        end
      end
    end
  end
end
