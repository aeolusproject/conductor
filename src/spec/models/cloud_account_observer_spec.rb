require 'spec_helper'

describe CloudAccountObserver do
  fixtures :all

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
end
