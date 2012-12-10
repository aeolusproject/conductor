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

describe ProviderAccount do
  fixtures :all
  before(:each) do
    @provider_account = Factory.build :mock_provider_account
  end

  it "should not be destroyable if it has instance with status other than stopped" do
    @provider_account.instances << Instance.new
    @provider_account.stub(:provider_images).and_return([])
    lambda {@provider_account.destroy}.should
      raise_error(Aeolus::Conductor::Base::NotDestroyable)
    @provider_account.instances.each { |i| i.state = "stopped" }
    @provider_account.check_destroyable_instances!.should be_true
    @provider_account.instances.clear
    @provider_account.check_destroyable_instances!.should be_true
    @provider_account.destroy.equal?(@provider_account).should be_true
    @provider_account.should be_frozen
  end

  it "should be destroyable if it has a config server" do
    @provider_account.stub(:provider_images).and_return([])
    @provider_account.destroy.equal?(@provider_account).should be_true
    @provider_account.should be_frozen
  end

  it "should not destroy associated credentials when account not destroyable" do
    @provider_account.credentials << FactoryGirl.build(:username_credential)
    @provider_account.save
    @provider_account.stub(:check_destroyable_instances!).and_return(false)
    @provider_account.destroy
    @provider_account.credentials.should_not be_empty
  end

  it "should check the validitiy of the cloud account login credentials" do
    mock_provider = FactoryGirl.create :mock_provider

    invalid_provider_account = Factory.build(:mock_provider_account, :provider => mock_provider)
    invalid_provider_account.credentials_hash = {'username' => "wrong_username", 'password' => "wrong_password"}
    invalid_provider_account.stub(:valid_credentials?).and_return(false)
    invalid_provider_account.should_not be_valid

    ec2_provider = FactoryGirl.create :ec2_provider
    invalid_ec2_provider_account = Factory.build(:ec2_provider_account, :provider => ec2_provider)
    invalid_ec2_provider_account.credentials_hash = {'username' => "", 'password' => nil}
    invalid_ec2_provider_account.stub(:valid_credentials?).and_return(false)
    invalid_ec2_provider_account.should_not be_valid

    valid_provider_account = Factory.build(:mock_provider_account, :provider => mock_provider)
    valid_provider_account.should be_valid
  end

  it "should fail to create a cloud account if the provider credentials are invalid" do
    provider_account = Factory.build(:mock_provider_account)
    provider_account.credentials_hash = {'password' => "wrong_password"}
    provider_account.stub(:valid_credentials?).and_return(false)
    provider_account.save.should == false
  end

  it "should add errors when testing credentials fails" do
    provider_account = Factory.build(:mock_provider_account)
    provider_account.credentials_hash = {'password' => "wrong_password"}
    provider_account.stub(:valid_credentials?).and_raise("DeltacloudError")
    provider_account.save.should == false
    provider_account.errors[:base].should == [I18n.t('provider_accounts.errors.exception_while_validating')]
  end

  it "should fail to create a cloud account if fetching of hw profiles fails" do
    provider_account = Factory.build(:mock_provider_account)
    provider_account.stub(:populate_hardware_profiles).and_raise(ActiveRecord::RecordInvalid)
    provider_account.save.should == false
  end

  it "should fail to create a cloud account if fetching of realms fails" do
    provider_account = Factory.build(:mock_provider_account)
    provider_account.stub(:populate_realms).and_raise(ActiveRecord::RecordInvalid)
    lambda {provider_account.save!}.should raise_exception
  end

  it "when calling connect and it fails with exception it will return nil" do
    DeltaCloud.stub(:new).and_raise(Exception)
    @provider_account.connect.should be_nil
  end

  it "should generate xml for a provider account with credentials" do
    provider_account = Factory.build(:ec2_provider_account)
    provider_account.credentials_hash = {
                                  'username' => 'user',
                                  'password' => 'pass',
                                  'account_id' => '1234',
                                  'x509private' => 'priv_key',
                                  'x509public' => 'cert'
                                 }
    expected_xml = %Q{<provider_account>
  <name>#{provider_account.label}</name>
  <provider>#{provider_account.provider.name}</provider>
  <provider_type>ec2</provider_type>
  <provider_credentials>
    <ec2_credentials>
      <access_key>user</access_key>
      <account_number>1234</account_number>
      <certificate>cert</certificate>
      <key>priv_key</key>
      <secret_access_key>pass</secret_access_key>
    </ec2_credentials>
  </provider_credentials>
</provider_account>}
    # default parameters for ProviderAccount#to_xml generates xml without credentials
    provider_account.to_xml(:with_credentials => true).should eql(expected_xml)
  end

  it "should generate xml for a provider account without credentials" do
    provider_account = Factory.build(:ec2_provider_account)
    provider_account.credentials_hash = {
                                  'username' => 'user',
                                  'password' => 'pass',
                                  'account_id' => '1234',
                                  'x509private' => 'priv_key',
                                  'x509public' => 'cert'
                                 }
    expected_xml = %Q{<provider_account>
  <name>#{provider_account.label}</name>
  <provider>#{provider_account.provider.name}</provider>
  <provider_type>ec2</provider_type>
</provider_account>}
    # default parameters for ProviderAccount#to_xml generates xml without credentials
    provider_account.to_xml.should eql(expected_xml)
    provider_account.to_xml(:with_credentials => false).should eql(expected_xml)
  end

  it "should create provider account with same username for different provider" do
    provider_account1 = FactoryGirl.create :mock_provider_account
    provider_account2 = Factory.build(:mock_provider_account, :provider => Factory.create(:mock_provider2))
    provider_account1.credentials_hash.should == provider_account2.credentials_hash
    provider_account2.should be_valid
  end

  it "should not fail to create more than one account per provider" do
    provider = FactoryGirl.create :mock_provider
    acc1 = FactoryGirl.create(:mock_provider_account, :provider => provider)
    acc2 = Factory.build(:mock_provider_account, :provider => provider)
    acc2.stub!(:valid_credentials?).and_return(true)
    acc2.stub!(:validate_unique_username).and_return(true)
    provider.provider_accounts << acc1
    provider.provider_accounts << acc2
    acc2.save.should == true
  end

  it "should require quota to be set" do
    @provider_account.should be_valid

    @provider_account.quota = nil
    @provider_account.should_not be_valid
  end

  it "should not set credentials in intialise" do
    @provider_account = ProviderAccount.new({:credentials_hash => {"username" => "test", "password" => "test"}})
    @provider_account.credentials_hash.should == {}
  end

  it "should not set credentials before provider is set" do
    @provider_account = ProviderAccount.new
    @provider_account.credentials_hash = {"username" => "test", "password" => "test"}
    @provider_account.credentials_hash.should == {}
  end

  it "should set credentials after provider is set" do
    provider = FactoryGirl.create :mock_provider
    @provider_account = ProviderAccount.new({:provider => provider})
    @provider_account.credentials_hash = {"username" => "test", "password" => "test"}
    @provider_account.credentials_hash.should == {"username" => "test", "password" => "test"}
  end

  context "validations" do
    context "priority" do
      it "can be positive integer" do
        @provider_account.priority = 7
        @provider_account.should be_valid
      end

      it "can be negative integer" do
        @provider_account.priority = -32
        @provider_account.should be_valid
      end

      it "can be zero" do
        @provider_account.priority = 0
        @provider_account.should be_valid
      end

      it "can be blank" do
        @provider_account.priority = ''
        @provider_account.should be_valid
      end

      it "can't be text" do
        @provider_account.priority = '(*&^$@!lkajsd'
        @provider_account.should_not be_valid
      end
    end
  end
end
