#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'spec_helper'

describe PoolFamily do

  before(:each) do
    @pool = FactoryGirl.create :pool
    @pool_family = @pool.pool_family
    @provider_account = Factory.build :mock_provider_account
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

  it "should not be valid if name is too long" do
    @pool_family.name = ('a' * 256)
    @pool_family.valid?.should be_false
    @pool_family.errors[:name].should_not be_nil
    @pool_family.errors[:name][0].should =~ /^is too long.*/
  end

  it "should not be valid if name contains special characters" do
    @pool_family.name = '.'
    @pool_family.valid?.should be_false
    @pool_family.errors[:name].should_not be_nil
    @pool_family.errors[:name][0].should =~ /^must only contain.*/
  end

  it "should require quota to be set" do
    @pool_family.should be_valid

    @pool_family.quota = nil
    @pool_family.should_not be_valid
  end

  it "should not destroy associated pools when pool family not destroyable" do
    # Stubbing only @pool_family doesn't work well on Rails 3.0 + Ruby 1.8.7
    PoolFamily.any_instance.stub(:check_name!).and_raise(Aeolus::Conductor::Base::NotDestroyable)
    lambda { @pool_family.destroy }.should raise_error
    @pool_family.pools.should_not be_empty
  end
end
