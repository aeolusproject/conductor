#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

require 'spec_helper'

describe ProviderAccount do
  fixtures :all
  before(:each) do
    @provider_account = Factory.build :mock_provider_account
  end

  it "should not be destroyable if it has instance with status other than stopped" do
    @provider_account.instances << Instance.new
    @provider_account.destroyable?.should be_false
    @provider_account.destroy.should be_false
    @provider_account.instances.each { |i| i.state = "stopped" }
    @provider_account.destroyable?.should be_true
    @provider_account.instances.clear
    @provider_account.destroyable?.should be_true
    @provider_account.destroy.equal?(@provider_account).should be_true
    @provider_account.should be_frozen
  end

  it "should be destroyable if it has a config server" do
    @provider_account.config_server = ConfigServer.new
    @provider_account.destroyable?.should be_true
    @provider_account.destroy.equal?(@provider_account).should be_true
    @provider_account.should be_frozen
  end

  it "should check the validitiy of the cloud account login credentials" do
    mock_provider = FactoryGirl.create :mock_provider

    invalid_provider_account = Factory.build(:mock_provider_account, :provider => mock_provider)
    invalid_provider_account.credentials_hash = {'username' => "wrong_username", 'password' => "wrong_password"}
    invalid_provider_account.should_not be_valid

    ec2_provider = FactoryGirl.create :ec2_provider
    invalid_ec2_provider_account = Factory.build(:ec2_provider_account, :provider => ec2_provider)
    invalid_ec2_provider_account.credentials_hash = {'username' => "", 'password' => nil}
    invalid_ec2_provider_account.valid_credentials?.should == false
    invalid_ec2_provider_account.should_not be_valid

    valid_provider_account = Factory.build(:mock_provider_account, :provider => mock_provider)
    valid_provider_account.should be_valid
  end

  it "should fail to create a cloud account if the provider credentials are invalid" do
    provider_account = Factory.build(:mock_provider_account)
    provider_account.credentials_hash = {'password' => "wrong_password"}
    provider_account.save.should == false
  end

  it "when calling connect and it fails with exception it will return nil" do
    DeltaCloud.should_receive(:new).and_raise(Exception.new)

    @provider_account.connect.should be_nil
  end

  it "should generate xml for a provider account" do
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
    provider_account.to_xml.should eql(expected_xml)
  end

  it "should create provider account with same username for different provider" do
    provider_account1 = FactoryGirl.create :mock_provider_account
    provider_account2 = Factory.build(:mock_provider_account, :provider => Factory.create(:mock_provider2))
    provider_account1.credentials_hash.should == provider_account2.credentials_hash
    provider_account2.should be_valid
  end

  it "should fail to create more than one account per provider" do
    provider = FactoryGirl.create :mock_provider
    acc1 = FactoryGirl.create(:mock_provider_account, :provider => provider)
    acc2 = Factory.build(:mock_provider_account, :provider => provider)
    acc2.stub!(:valid_credentials?).and_return(true)
    acc2.stub!(:validate_unique_username).and_return(true)
    provider.provider_accounts << acc1
    provider.provider_accounts << acc2
    acc2.save.should == false
    acc2.errors[:base].should include('Only one account is supported per provider')
  end

  it "should require quota to be set" do
    @provider_account.should be_valid

    @provider_account.quota = nil
    @provider_account.should_not be_valid
  end
end
