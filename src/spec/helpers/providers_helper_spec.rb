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

require 'spec_helper'

describe ProvidersHelper do
  include ProvidersHelper

  context "edit_button() helper" do

    it "formats link with path to edit action if rendered in show or accounts action" do
      provider = FactoryGirl.create(:mock_provider)

      edit_button(provider, 'show').should =~ /providers\/[0-9]*\/edit/
    end

    it "formats blank link with no action and with disabled class if not in show or accounts action" do
      provider = FactoryGirl.create(:mock_provider)

      edit_button = edit_button(provider, 'index')
      edit_button.should =~ /href="#"/
      edit_button.should =~ /disabled/
    end

  end

end
