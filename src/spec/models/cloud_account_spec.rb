require 'spec_helper'

describe CloudAccount do
  fixtures :all
  before(:each) do
    @cloud_account = Factory :mock_cloud_account
  end

  it "should not be destroyable if it has instances" do
    @cloud_account.instances << Instance.new
    @cloud_account.destroyable?.should be_false
    @cloud_account.destroy.should be_false

    @cloud_account.instances.clear
    @cloud_account.destroyable?.should be_true
    @cloud_account.destroy.equal?(@cloud_account).should be_true
    @cloud_account.should be_frozen
  end

  it "should check the validitiy of the cloud account login credentials" do
    mock_provider = Factory :mock_provider

    invalid_cloud_account = Factory.build(:cloud_account, :username => "wrong_username", :password => "wrong_password", :provider => mock_provider)
    invalid_cloud_account.should_not be_valid

    valid_cloud_account = Factory.build(:mock_cloud_account, :provider => mock_provider)
    valid_cloud_account.should be_valid
  end

  it "should fail to create a cloud account if the provider credentials are invalid" do
    cloud_account = Factory.build(:mock_cloud_account, :password => "wrong_password")
    cloud_account.save.should == false
  end

  it "should create an instance_key if provider is EC2" do
    @client = mock('DeltaCloud', :null_object => true)
    @provider = Factory.build :ec2_provider
    @key = mock('Key', :null_object => true)
    @key.stub!(:pem).and_return("PEM")
    @key.stub!(:id).and_return("1_user")
    @client.stub!(:"feature?").and_return(true)
    @client.stub!(:"create_key").and_return(@key)

    cloud_account = Factory.build :ec2_cloud_account
    cloud_account.stub!(:connect).and_return(@client)
    cloud_account.save
    cloud_account.instance_key.should_not == nil
    cloud_account.instance_key.pem == "PEM"
    cloud_account.instance_key.id == "1_user"
  end

  it "when calling connect and it fails with exception it will return nil" do
    DeltaCloud.should_receive(:new).and_raise(Exception.new)

    @cloud_account.connect.should be_nil
  end

  it "should generate credentials xml" do
    expected_xml = <<EOT
<?xml version="1.0"?>
<provider_credentials>
  <ec2_credentials>
    <account_number>1234</account_number>
    <access_key>user</access_key>
    <secret_access_key>pass</secret_access_key>
    <certificate>cert</certificate>
    <key>priv_key</key>
  </ec2_credentials>
</provider_credentials>
EOT
    cloud_account = Factory.build(:mock_cloud_account,
                                  :username => 'user',
                                  :password => 'pass',
                                  :account_number => '1234',
                                  :x509_cert_priv => 'priv_key',
                                  :x509_cert_pub => 'cert'
                                 )
    cloud_account.build_credentials.should eql(expected_xml)
  end
end
