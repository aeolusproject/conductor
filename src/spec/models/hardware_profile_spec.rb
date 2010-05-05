require 'spec_helper'

describe HardwareProfile do
  before(:each) do
    @hp = Factory.create(:mock_hwp1)
  end

  it "should create a new hardware profile" do
    @hp.should be_valid
  end

  it "should not validate for missing name" do
    [nil, ""].each do |value|
      @hp.name = value
      @hp.should_not be_valid
    end

    @hp.name = 'valid name'
    @hp.should be_valid
  end

  it "should require unique names" do
    hp2 = Factory.create(:mock_hwp2)
    @hp.should be_valid
    hp2.should be_valid

    hp2.name = @hp.name
    hp2.should_not be_valid
  end

  it "should require valid amount of memory" do
    [nil, "hello", -1].each do |fail_value|
      @hp.memory = fail_value
      @hp.should_not be_valid
    end
  end

  it "should require valid amount of storage" do
    [nil, "hello", -1].each do |fail_value|
      @hp.storage = fail_value
      @hp.should_not be_valid
    end
  end

  it "should not require architecture when there's no provider" do
    @hp.architecture = nil
    @hp.should be_valid
  end

  it "should require architecture when it's with provider" do
    @hp.provider = Provider.new

    @hp.should be_valid
    @hp.architecture = nil
    @hp.should_not be_valid
  end

  it "should allow Aggregator profiles only for provider profiles" do
    @hp.provider = nil

    @hp.aggregator_hardware_profiles << @hp
    @hp.should have(1).error_on(:aggregator_hardware_profiles)
    @hp.errors.on(:aggregator_hardware_profiles).should eql(
      "Aggregator profiles only allowed for provider profiles")

    @hp.aggregator_hardware_profiles.clear
    @hp.should be_valid
  end

  it "should allow Provider profiles only for aggregator profiles" do
    @hp.provider = Provider.new

    @hp.aggregator_hardware_profiles << @hp
    @hp.should have(1).error_on(:provider_hardware_profiles)
    @hp.errors.on(:provider_hardware_profiles).should eql(
      "Provider profiles only allowed for aggregator profiles")

    @hp.provider_hardware_profiles.clear
    @hp.should be_valid
  end

end
