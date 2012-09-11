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

describe Pool do
  before(:each) do
  end

  it "should require unique name" do
    pool1 = Factory.create(:pool)
    pool2 = Factory.create(:pool)
    pool1.should be_valid
    pool2.should be_valid

    pool2.name = pool1.name
    pool2.should_not be_valid
  end

  it "should not be valid if name is too long" do
    u = FactoryGirl.create(:pool)
    u.name = ('a' * 256)
    u.valid?.should be_false
    u.errors[:name].should_not be_nil
    u.errors[:name][0].should =~ /^is too long.*/
  end

  it "should not be destroyable when it has running instances" do
    pool = Factory.create(:pool)
    Pool.find(pool.id).should be_destroyable

    instance = Factory.create(:instance, :pool_id => pool.id)
    Pool.find(pool.id).should_not be_destroyable

    instance.state = Instance::STATE_STOPPED
    instance.save!
    Pool.find(pool.id).should be_destroyable
  end

  it "should not be destroyable when it has stopped stateful instances" do
    pool = Factory.build(:pool)
    pool.should be_destroyable

    instance = Factory.build(:instance, :pool_id => pool.id)
    instance.stub!(:restartable?).and_return(true)
    pool.instances << instance
    pool.should_not be_destroyable

    instance.state = Instance::STATE_STOPPED
    instance.stub!(:restartable?).and_return(true)
    pool.should_not be_destroyable
  end

  it "should not destroy associated catalogs when pool not destroyable" do
    pool = FactoryGirl.build(:pool)
    pool.catalogs << FactoryGirl.build(:catalog, :pool => pool)
    pool.stub(:destroyable?).and_return(false)
    pool.destroy
    pool.catalogs.should_not be_empty
  end

  it "should require quota to be set" do
    pool = FactoryGirl.create :pool
    pool.should be_valid

    pool.quota = nil
    pool.should_not be_valid
  end

end
