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

describe DeployableMatching::Validator do

  context "deployable level validations" do
    before(:each) do
      @pool = FactoryGirl.create(:pool)
      catalog = FactoryGirl.create(:catalog, :pool => @pool)
      @deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])
      @user = FactoryGirl.create(:user)
    end

    it "should return error when no provider account is associated with the pool" do
      @pool.pool_family.provider_accounts.delete_all
      errors = DeployableMatching::Validator.errors_for_deployable(@pool, @user, @deployable.deployable_xml)
      errors.should include('There are no Provider Accounts associated with the selected Pool\'s Environment.')
    end

    it "should return error when pool quota was reached" do
      @pool.quota.maximum_running_instances = 0
      errors = DeployableMatching::Validator.errors_for_deployable(@pool, @user, @deployable.deployable_xml)
      errors.should include('Pool quota reached')
    end

    it "should return error when pool_family quota was reached" do
      @pool.pool_family.quota.maximum_running_instances = 0
      errors = DeployableMatching::Validator.errors_for_deployable(@pool, @user, @deployable.deployable_xml)
      errors.should include('Environment quota reached')
    end

    it "should return error when user quota was reached" do
      @user.quota.maximum_running_instances = 0
      errors = DeployableMatching::Validator.errors_for_deployable(@pool, @user, @deployable.deployable_xml)
      errors.should include('User quota reached')
    end
  end

  context "assembly level validations" do
    before(:each) do
      pool = FactoryGirl.create(:pool)
      catalog = FactoryGirl.create(:catalog, :pool => pool)
      deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])
      @assembly = deployable.deployable_xml.assemblies.first
      @assembly_hwp = FactoryGirl.create(:mock_hwp1)
    end

    it "should return error when no hwp exists" do
      errors = DeployableMatching::Validator.errors_for_assembly(@assembly, nil)
      errors.should include('You do not have sufficient permission to access the front_hwp1 Hardware Profile.')
    end

    it "should return error when no base images exists" do
      DeployableMatching::ImageFetcher.stub(:base_image).and_return(nil)
      errors = DeployableMatching::Validator.errors_for_assembly(@assembly, @assembly_hwp)
      errors.should include("No image build was found with uuid #{@assembly.image_build} and no image was found with uuid #{@assembly.image_id}")
    end

    it "should return error when arch mismatches" do
      base_image = FactoryGirl.create(:base_image_with_template)
      DeployableMatching::ImageFetcher.stub(:base_image).and_return(base_image)
      DeployableMatching::ImageFetcher.stub(:image_arch).and_return('fooarch')

      errors = DeployableMatching::Validator.errors_for_assembly(@assembly, @assembly_hwp)
      errors.should include('Assembly hardware profile architecture (x86_64) doesn\'t match image hardware profile architecture (fooarch).')
    end
  end

  context "provider_account level validations" do
    before(:each) do
      @assembly = mock(:assembly, :requires_config_server? => false)

      @provider_account = FactoryGirl.create(:mock_provider_account, :label => 'test_account')

      @provider_hwp = FactoryGirl.create(:mock_hwp1)

      Tim::ProviderImage.any_instance.stub(:create_factory_provider_image).and_return(true)
      Tim::TargetImage.any_instance.stub(:create_factory_target_image).and_return(true)
      @provider_image = FactoryGirl.create(:provider_image)
    end

    it "should return error when the provider is disabled" do
      @provider_account.provider.enabled = false
      errors = DeployableMatching::Validator.errors_for_provider_account(@assembly, @provider_account, @provider_hwp, @provider_image)
      errors.should include('test_account: Provider must be enabled')
    end

    it "should return error when the provider is unavailable" do
      @provider_account.provider.available = false
      errors = DeployableMatching::Validator.errors_for_provider_account(@assembly, @provider_account, @provider_hwp, @provider_image)
      errors.should include('test_account: Provider is not available')
    end

    it "should return error when provider_account quota was reached" do
      @provider_account.quota.maximum_running_instances = 0
      errors = DeployableMatching::Validator.errors_for_provider_account(@assembly, @provider_account, @provider_hwp, @provider_image)
      errors.should include('test_account: Provider Account quota reached')
    end

    it "should return error when no provider hwp exists" do
      errors = DeployableMatching::Validator.errors_for_provider_account(@assembly, @provider_account, nil, @provider_image)
      errors.should include('test_account: Hardware Profile match not found')
    end

    it "should return error when no provider image exists" do
      errors = DeployableMatching::Validator.errors_for_provider_account(@assembly, @provider_account, @provider_hwp, nil)
      errors.should include('test_account: Image is not pushed to this Provider Account')
    end

    it "should return error when no config server exists" do
      assembly = mock(:assembly, :requires_config_server? => true)
      errors = DeployableMatching::Validator.errors_for_provider_account(assembly, @provider_account, @provider_hwp, @provider_image)
      errors.should include('test_account: no Config Server available for Provider Account')
    end
  end

end
