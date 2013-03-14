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

describe ProviderSelection::Base do

  before(:each) do
    @provider_account = FactoryGirl.create(:mock_provider_account, :label => "test_account")

    assembly_match = DeployableMatching::AssemblyMatch.new(@provider_account, nil, nil, nil, nil, nil)
    assembly_instance = DeployableMatching::AssemblyInstance.new(nil, nil, nil, [assembly_match])
    assembly_instances = [assembly_instance]

    pool = FactoryGirl.create(:pool)
    @provider_selection = ProviderSelection::Base.new(pool, assembly_instances)
  end

  it "should give back valid match" do
    match = @provider_selection.next_match
    match.provider_account.should eql(@provider_account)
  end

  it "should calculate initial rank" do
    rank = @provider_selection.calculate
    rank.priority_groups.length.should eql(1)

    priority_group = rank.priority_groups.first
    priority_group.matches.length.should eql(1)

    match = priority_group.matches.first
    match.provider_account.should eql(@provider_account)
  end

end
