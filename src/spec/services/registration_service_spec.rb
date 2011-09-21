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

describe RegistrationService do

  fixtures :all
  before(:each) do
  end

  describe "with validations" do

    it "should return errors on user when user is missing required fields" do
      user = User.new(:login => 'baduser')
      user.quota = Quota.new
      r = RegistrationService.new(user)
      r.save.should be_false
      user.errors.empty?.should be_false
      user.errors.find_all do |attr,msg|
        [:email, :password,  :password_confirmation].include?(attr).should be_true
      end
    end

    it "should register a user with default pool/quota/role perms when default settings set" do
      @user = FactoryGirl.create :user
      @pool = MetadataObject.lookup("self_service_default_pool")
      @role = MetadataObject.lookup("self_service_default_role")
      @quota = FactoryGirl.create :quota
      MetadataObject.set("self_service_default_quota", @quota)

      @registration_service = RegistrationService.new(@user)
      @registration_service.save

      @pools = Pool.list_for_user(@user, Privilege::CREATE, :target_type => Instance)
      @pools.length.should == 1
      @pools[0].name.should == "Default"

      @user.quota.maximum_running_instances.should == @quota.maximum_running_instances
      @user.quota.maximum_total_instances.should == @quota.maximum_total_instances
    end

  end

  describe "with quota" do

    it "passed via nested attributes to user model" do
      user = Factory.build(:user)
      user.quota = Quota.new(:maximum_running_instances => 2, :maximum_total_instances => 5)
      registration_process = RegistrationService.new(user)

      lambda do
        lambda do
          lambda do
            registration_process.save.should be_true
          end.should change(Permission, :count).by(3)
        end.should change(User, :count).by(1)
      end.should change(Quota, :count).by(1)

      user.new_record?.should be_false
      user.quota.maximum_running_instances.should == 2
      user.quota.maximum_total_instances.should == 5
    end

    it "no quota attributes passed via nested attributes" do
      user = Factory.build(:user)
      registration_process = RegistrationService.new(user)

      lambda do
        registration_process.save.should be_true
      end.should_not change(Quota, :count)

      user.quota.maximum_running_instances.should == 10
      user.quota.maximum_total_instances.should == 15
    end
  end

  describe "with transaction" do

    it "doesn't save user if quota save! raise error and return false if validation failed" do
      user_attributes = Factory.attributes_for(:user)
      user = User.new(user_attributes)
      registration_process = RegistrationService.new(user)

      q = Quota.new(:maximum_total_instances => 'error')
      Quota.should_receive(:new).and_return(q)

      lambda do
        registration_process.save.should be_false
      end.should_not change(User, :count)
    end

    it "doesn't save quota if user save! raise error" do
      user_attributes = Factory.attributes_for(:user)
      user = User.new(user_attributes)
      user.quota = Quota.new
      user.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(user))
      registration_process = RegistrationService.new(user)

      lambda do
        lambda do
          registration_process.save.should be_false
        end.should_not change(Quota, :count)
      end.should_not change(User, :count)
    end

  end

end
