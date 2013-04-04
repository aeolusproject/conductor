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

describe DeployableMatching::AssemblyInstancesBuilder do

  before(:each) do
    @pool = FactoryGirl.create(:pool)
  end

  it "should build assembly instances from deployable" do
    admin = FactoryGirl.create(:admin_user)
    session = FactoryGirl.create(:session)
    permission_session =
      Alberich::PermissionSession.create!(:user => admin,
                                :session_id => session.session_id)

    catalog = FactoryGirl.create(:catalog, :pool => @pool)
    deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])

    DeployableMatching::Validator.stub(:errors_for_deployable).and_return([])
    DeployableMatching::Validator.stub(:errors_for_assembly).and_return([])

    frontend_hwp = FactoryGirl.create(:mock_hwp1)
    HardwareProfile.stub(:allowed_frontend_hwp).and_return(frontend_hwp)

    matches_builder = mock('matches_builder', :errors => [], :assembly_matches => [])
    DeployableMatching::AssemblyMatchesBuilder.stub(:build).and_return(matches_builder)

    builder =
      DeployableMatching::AssemblyInstancesBuilder.build_from_deployable(
        permission_session, admin, @pool, deployable.deployable_xml)

    builder.assembly_instances.length.should == deployable.deployable_xml.assemblies.length
    builder.errors.should be_empty
  end

  it "should build assembly instances from instances" do
    instance = FactoryGirl.create(:instance)

    matches_builder = mock('matches_builder', :errors => [], :assembly_matches => [])
    DeployableMatching::AssemblyMatchesBuilder.stub(:build).and_return(matches_builder)

    builder =
      DeployableMatching::AssemblyInstancesBuilder.build_from_instances(
        @pool, [instance]
      )

    builder.assembly_instances.length.should == 1
    builder.errors.should be_empty
  end

  it 'should report deployable level error messages' do
    admin = FactoryGirl.create(:admin_user)
    session = FactoryGirl.create(:session)
    permission_session =
      Alberich::PermissionSession.create!(:user => admin,
                                :session_id => session.session_id)

    catalog = FactoryGirl.create(:catalog, :pool => @pool)
    deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])

    DeployableMatching::Validator.stub(:errors_for_deployable).and_return(['Very serious error message.'])

    builder =
      DeployableMatching::AssemblyInstancesBuilder.build_from_deployable(
        permission_session, admin, @pool, deployable.deployable_xml)

    builder.assembly_instances.should be_empty
    builder.errors.length.should == 1
    builder.errors.should include('Very serious error message.')
  end

  it 'should report assembly level error messages' do
    admin = FactoryGirl.create(:admin_user)
    session = FactoryGirl.create(:session)
    permission_session =
      Alberich::PermissionSession.create!(:user => admin,
                                :session_id => session.session_id)

    catalog = FactoryGirl.create(:catalog, :pool => @pool)
    deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])

    DeployableMatching::Validator.stub(:errors_for_deployable).and_return([])
    DeployableMatching::Validator.stub(:errors_for_assembly).and_return(['Very serious error message.'])

    frontend_hwp = FactoryGirl.create(:mock_hwp1)
    HardwareProfile.stub(:allowed_frontend_hwp).and_return(frontend_hwp)

    builder =
      DeployableMatching::AssemblyInstancesBuilder.build_from_deployable(
        permission_session, admin, @pool, deployable.deployable_xml)

    builder.assembly_instances.compact.should be_empty
    builder.errors.length.should == 2
    builder.errors.should include('Very serious error message.')
  end

end
