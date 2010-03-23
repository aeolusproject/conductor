require 'spec_helper'

describe Provider do
  before(:each) do
    @provider = Factory.create(:mock_provider)
    @client = mock('DeltaCloud', :null_object => true)
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

  it "should require unique name" do
    provider1 = Factory.create :mock_provider
    provider2 = Factory.create :mock_provider
    provider1.should be_valid
    provider2.should be_valid

    provider2.name = provider1.name
    provider2.should_not be_valid
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

  it "should log errors when connecting to invalid url" do
    @logger = mock('Logger', :null_object => true)
    @provider = Factory.create(:mock_provider)
    @provider.stub!(:logger).and_return(@logger)

    @provider.should be_valid
    @provider.logger.should_receive(:error).twice
    @provider.url = "http://invalid.provider/url"
    @provider.connect.should be_nil
  end

end
