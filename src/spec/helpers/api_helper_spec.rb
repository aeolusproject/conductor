#
#   Copyright 2012 Red Hat, Inc.
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

require 'spec_helper'

describe ApiHelper do

  let(:api_helper) { Object.new.extend(ApiHelper) }

  describe "xmlschema_datetime" do
    subject { api_helper.xmlschema_datetime(datetime) }

    context "simple datetime" do
      # Aeolus Developer Conference 2012
      let(:datetime) { DateTime.new(2012, 11, 5, 9, 15, 3, '+1') }

      it { should == "2012-11-05T09:15:03+01:00" }
    end

    context "datetime with sub-second time information" do
      let(:datetime) { DateTime.new(2012, 11, 5, 9, 15, Rational(345, 100), '+1') }

      it { should == "2012-11-05T09:15:03.45+01:00" }
    end
  end

  describe "xmlschema_absolute_duration" do
    subject { api_helper.xmlschema_absolute_duration(duration) }

    context "zero duration" do
      let(:duration) { 0 }

      it { should == "P0DT0H0M0S" }
    end

    context "Rational duration with decimal places" do
      let(:duration) { Rational(314159, 100000) }

      it { should == "P0DT0H0M3.14159S" }
    end

    context "float duration with no value at decimal places" do
      let(:duration) { 1.0 }

      it "should print 1S, not 1.0S" do
        subject.should == "P0DT0H0M1S"
      end
    end

    context "long duration" do
      let(:duration) { 456 * 24 * 60 * 60 + # days
                       8 * 60 * 60 + # hours
                       57 * 60 + # minutes
                       3 } # seconds

      it { should == "P456DT8H57M3S" }
    end

    context "BigDecimal duration" do
      let(:duration) { BigDecimal.new('0.123123123123123123') }
      subject { api_helper.xmlschema_absolute_duration(duration, nil) }

      it { should == "P0DT0H0M0.123123123123123123S" }
    end

    context "seconds end with zero, no decimal point" do
      let(:duration) { BigDecimal.new('10') }

      it { should == "P0DT0H0M10S" }
    end
  end

end
