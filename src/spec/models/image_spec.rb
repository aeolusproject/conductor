require 'spec_helper'

describe Image do
  before(:each) do
    @provider = Factory.build(:mock_provider)
    @client = mock('DeltaCloud', :null_object => true)
    @provider.stub!(:connect).and_return(@client)
  end

  it "should have a unique external key" do
    i1 = Factory.create(:image, :provider => @provider)
    i2 = Factory.create(:image, :provider => @provider)
    @provider.images = [i1, i2]
    i1.should be_valid
    i2.should be_valid

    i2.external_key = i1.external_key
    i2.should_not be_valid
  end

  it "should have a name" do
    i = Factory.build(:image, :name => nil)
    i.should_not be_valid

    i.name = ''
    i.should_not be_valid

    i.name = "valid name"
    i.should be_valid
  end

  it "should not have a name that is too long" do
    i = Factory.build(:image)
    i.name = 'x' * 1025
    i.should_not be_valid

    i.name = 'x' * 1024
    i.should be_valid
  end

  it "should have an architecture if it has a provider" do
    i = Factory.build(:image, :architecture => nil)
    i.should_not be_valid

    i.architecture = 'i686'
    i.should be_valid
  end

  it "should have either a provider or a pool specified" do
    i = Factory.build(:image, :provider => nil, :pool => nil)
    i.should have(1).error_on(:provider)
    i.should have(1).error_on(:pool)
    i.errors.on(:provider).should eql(
      "provider or pool must be specified")
    i.errors.on(:pool).should eql(
      "provider or pool must be specified")

    i.provider = @provider
    i.should be_valid

    i.pool = Factory.build(:pool)
    i.should have(1).error_on(:provider)
    i.should have(1).error_on(:pool)
    i.errors.on(:provider).should eql(
      "provider or pool must be blank")
    i.errors.on(:pool).should eql(
      "provider or pool must be blank")

    i.provider = nil
    i.should be_valid
  end

  it "should have provider images only if it has a provider" do
    i = Factory.create(:image, :pool => Pool.new,
                     :provider => nil)

    i.aggregator_images << i
    i.should have(1).error_on(:aggregator_images)
    i.errors.on(:aggregator_images).should eql(
      "Aggregator image only allowed for provider images")

    i.aggregator_images.clear
    i.should be_valid
  end

  it "should have aggregator images only if it has a pool" do
    i = Factory.create(:image)

    i.provider_images << i
    i.should have(1).error_on(:provider_images)
    i.errors.on(:provider_images).should eql(
      "Provider images only allowed for aggregator images")

    i.provider_images.clear
    i.should be_valid
  end

end
