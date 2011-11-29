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
