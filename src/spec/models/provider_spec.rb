require 'spec_helper'

describe Provider do
  context "(using stubbed out connect method)" do
    before(:each) do
      @client = mock('DeltaCloud', :null_object => true)
      @provider = Factory.build(:mock_provider)
      @provider.stub!(:connect).and_return(@client)
    end

    it "should return a client object" do
      @provider.send(:valid_framework?).should be_true
    end

    it "should validate mock provider" do
      @provider.should be_valid
    end

    it "should require a valid name" do
      [nil, ""].each do |invalid_value|
        @provider.name = invalid_value
        @provider.should_not be_valid
      end
    end

    it "should require a valid cloud_type" do
      [nil, ""].each do |invalid_value|
        @provider.cloud_type = invalid_value
        @provider.should_not be_valid
      end
    end

    it "should require a valid url" do
      [nil, ""].each do |invalid_value|
        @provider.url = invalid_value
        @provider.should_not be_valid
      end
    end

    it "should be able to connect to the specified framework" do
      @provider.should be_valid
      @provider.connect.should_not be_nil

      @provider.url = "http://invalid.provider/url"
      @provider.stub(:connect).and_return(nil)
      deltacloud = @provider.connect
      @provider.should have(1).error_on(:url)
      @provider.errors.on(:url).should eql("must be a valid provider url")
      @provider.should_not be_valid
      deltacloud.should be_nil
    end

    it "should require unique name" do
      @provider.save!
      provider2 = Factory.build :mock_provider
      provider2.stub!(:connect).and_return(@client)
      provider2.should be_valid

      provider2.name = @provider.name
      provider2.should_not be_valid
    end

    it "should set valid cloud type" do
      @client.driver_name = @provider.cloud_type
      @provider.cloud_type = nil
      @provider.set_cloud_type!
      @provider.should be_valid
    end

    it "should not destroy provider if deletion of associated cloud account fails" do
      # TODO: front end HW profiles are not deleted with provider, which
      # involves "External name is already used" error.
      # This should be solved when implementing "Scripted import of Hardware Profiles
      # from EC2" scenario, then it's possible to delete this line
      # note: same situation will be with images
      HardwareProfile.destroy_all

      instance = Factory(:instance)
      provider = instance.cloud_account.provider
      provider.destroy
      provider.destroyed?.should be_false
    end
  end

  context "(using original connect method)" do
    it "should log errors when connecting to invalid url" do
      @logger = mock('Logger', :null_object => true)
      @provider = Factory.build(:mock_provider)
      @provider.stub!(:logger).and_return(@logger)

      @provider.logger.should_receive(:error).twice
      @provider.url = "http://invalid.provider/url"
      @provider.connect.should be_nil
    end
  end

end
