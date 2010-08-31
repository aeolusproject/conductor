require 'spec_helper'

describe Zone do

  before(:each) do
    @pool = Factory :pool
    @zone = @pool.zone
    @cloud_account = Factory :mock_cloud_account
    @cloud_account.zones << @zone
    @cloud_account.save!
  end

  it "should validate default zone" do
    @zone.should be_valid
  end

  it "should require a valid name" do
    [nil, ""].each do |invalid_value|
      @zone.name = invalid_value
      @zone.should_not be_valid
    end
  end

  it "should have pool" do
    @zone.pools.size.should == 1
    @zone.pools[0].id.should == @pool.id
  end

  it "should have account" do
    @zone.cloud_accounts.size.should == 1
    @zone.cloud_accounts[0].id.should == @cloud_account.id
  end

end
