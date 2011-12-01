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
    describe SyslogConverter do

      describe "#new" do

        before(:each) do
          @c = SyslogConverter.new
          event = Aeolus::Event::Cidr.new({:owner=>'fred', :hardware_profile => 'm1.large'})
          @res = @c.transform(event)
        end
      end

      describe "#emit" do

        before(:each) do
          @c = SyslogConverter.new
          event = Aeolus::Event::Cidr.new({:owner=>'fred', :hardware_profile => 'm1.large'})
          @c.transform(event)
        end

        it "should send the formatted message to syslog" do
          Syslog.stub!(:open).and_return(nil)
          Syslog.should_receive(:open).with(anything(),anything(),Syslog::LOG_LOCAL6).once
          @c.emit
        end
      end
    end
  end
end
