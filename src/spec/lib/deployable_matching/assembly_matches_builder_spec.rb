#
#   Copyright 2013 Red Hat, Inc.
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

describe DeployableMatching::AssemblyMatchesBuilder do

  it 'should find assembly matches' do
    provider_account1 = FactoryGirl.create(:mock_provider_account, :label => 'test_account1')
    provider_account2 = FactoryGirl.create(:mock_provider_account, :label => 'test_account2')
    provider_account3 = FactoryGirl.create(:mock_provider_account, :label => 'test_account3')
    provider_accounts = [provider_account1, provider_account2, provider_account3]

    assembly_instance = DeployableMatching::AssemblyInstance.new(nil, {}, nil, nil)

    HardwareProfile.stub(:match_provider_hardware_profile)
    DeployableMatching::ImageFetcher.stub(:provider_image)
    DeployableMatching::Validator.stub(:errors_for_provider_account).and_return([])

    builder = DeployableMatching::AssemblyMatchesBuilder.build(assembly_instance,
                                                               provider_accounts)

    builder.assembly_matches.length.should == 3
    builder.errors.should be_empty
    provider_account_matches = builder.assembly_matches.map(&:provider_account)
    provider_account_matches.should include(provider_account1)
    provider_account_matches.should include(provider_account2)
    provider_account_matches.should include(provider_account3)
  end

  it 'should report error messages' do
    provider_account = FactoryGirl.create(:mock_provider_account, :label => 'test_account')
    provider_accounts = [provider_account]

    assembly_instance = DeployableMatching::AssemblyInstance.new(nil, {}, nil, nil)

    HardwareProfile.stub(:match_provider_hardware_profile)
    DeployableMatching::ImageFetcher.stub(:provider_image)
    DeployableMatching::Validator.stub(:errors_for_provider_account).and_return(['Very serious error message'])

    builder = DeployableMatching::AssemblyMatchesBuilder.build(assembly_instance,
                                                               provider_accounts)

    builder.assembly_matches.should be_empty
    builder.errors.length.should == 1
    builder.errors.should include('Very serious error message')
  end

  it 'should filter already launched assembly matches' do
    provider_account = FactoryGirl.create(:mock_provider_account, :label => 'test_account')
    provider_accounts = [provider_account]
    instance = Factory.build(:instance)

    assembly_instance = DeployableMatching::AssemblyInstance.new(nil, {}, nil, nil)

    mock_hwp1 = FactoryGirl.create(:mock_hwp1)
    HardwareProfile.stub(:match_provider_hardware_profile).and_return(mock_hwp1)

    Tim::ProviderImage.any_instance.stub(:create_factory_provider_image).and_return(true)
    Tim::TargetImage.any_instance.stub(:create_factory_target_image).and_return(true)
    provider_image = FactoryGirl.create(:provider_image)
    DeployableMatching::ImageFetcher.stub(:provider_image).and_return(provider_image)

    DeployableMatching::Validator.stub(:errors_for_provider_account).and_return([])

    FactoryGirl.create(:instance_match,
                       :instance => instance,
                       :provider_account => provider_account,
                       :hardware_profile => mock_hwp1,
                       :provider_image => provider_image.external_image_id)

    builder = DeployableMatching::AssemblyMatchesBuilder.build(assembly_instance,
                                                               provider_accounts,
                                                               nil, instance)

    builder.assembly_matches.should be_empty
    builder.errors.length.should == 1
    builder.errors.should include('No more matches left. All of them are tried already.')
  end

end