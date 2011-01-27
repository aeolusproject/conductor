require 'spec_helper'

describe ProviderAccountObserver do
  fixtures :all

  it "should create an instance_key if provider is EC2" do
    @client = mock('Conductor', :null_object => true)
    @provider = Factory.build :ec2_provider
    @key = mock('Key', :null_object => true)
    @key.stub!(:pem).and_return("PEM")
    @key.stub!(:id).and_return("1_user")
    @client.stub!(:"feature?").and_return(true)
    @client.stub!(:"create_key").and_return(@key)

    provider_account = Factory.build :ec2_provider_account
    provider_account.stub!(:connect).and_return(@client)
    provider_account.stub!(:generate_auth_key).and_return(@key)
    provider_account.save
    provider_account.instance_key.should_not == nil
    provider_account.instance_key.pem == "PEM"
    provider_account.instance_key.id == "1_user"
  end
end
