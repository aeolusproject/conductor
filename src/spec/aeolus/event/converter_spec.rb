#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
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
