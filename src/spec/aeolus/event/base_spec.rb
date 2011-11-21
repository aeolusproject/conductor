require 'event_spec_helper'

module Aeolus
  module Event
    describe Base do

      describe "#new" do
        it "should set default values on creation" do
          event = Base.new
          event.target.should == "syslog"
        end
      end

      describe "#process" do
        it "should return true when an event is sent successfully" do
          event = Base.new
          result = event.process
          result.should be_true
        end
      end
      describe "#attributes" do
        it "should return the attributes defined in the Base class as a single level array" do
          event = Base.new
          event.attributes.include?(:event_id).should be_true
          event.attributes.include?(:target).should be_true
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
