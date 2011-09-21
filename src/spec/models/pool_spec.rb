#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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

  it "should require quota to be set" do
    pool = FactoryGirl.create :pool
    pool.should be_valid

    pool.quota = nil
    pool.should_not be_valid
  end

end
