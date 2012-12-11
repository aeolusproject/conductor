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

end
