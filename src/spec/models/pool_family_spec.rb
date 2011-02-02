require 'spec_helper'

describe PoolFamily do

  before(:each) do
    @pool = Factory :pool
    @pool_family = @pool.pool_family
    @provider_account = Factory :mock_provider_account
    @provider_account.pool_families << @pool_family
    @provider_account.save!
  end

  it "should validate default pool family" do
    @pool_family.should be_valid
  end

  it "should require a valid name" do
    [nil, ""].each do |invalid_value|
      @pool_family.name = invalid_value
      @pool_family.should_not be_valid
    end
  end

  it "should have pool" do
    @pool_family.pools.size.should == 2 #default pool + pool created here
    @pool.pool_family.id.should == @pool_family.id
  end

  it "should have account" do
    @pool_family.provider_accounts.size.should == 1
    @pool_family.provider_accounts[0].id.should == @provider_account.id
  end

end
