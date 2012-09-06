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

describe User do
  before(:each) do
  end

  it "should create a new user 'tuser'" do
    user = Factory.create(:tuser)
    user.should be_valid
  end

  it "should require password confirmation" do
    user = Factory.build :tuser
    user.should be_valid
    user.password_confirmation = "different password"
    user.should_not be_valid
  end

  it "should require unique username" do
    user1 = Factory.create(:tuser)
    user2 = Factory.create(:tuser)
    user1.should be_valid
    user2.should be_valid

    user2.username = user1.username
    user2.should_not be_valid
  end

  it "should require valid email" do
    user = FactoryGirl.create(:email_user)
    user.should be_valid

    user = FactoryGirl.create(:email_user, :email => "foo@bar.org")
    user.should be_valid

    user.email = "invalid"
    user.should_not be_valid
  end

  it "should not be valid if first name is too long" do
    u = FactoryGirl.create(:tuser)
    u.first_name = ('a' * 256)
    u.valid?.should be_false
    u.errors[:first_name].first.should_not be_nil
    u.errors[:first_name].first.should =~ /^is too long.*/
  end

  it "should not be valid if last name is too long" do
    u = FactoryGirl.create(:tuser)
    u.last_name = ('a' * 256)
    u.valid?.should be_false
    u.errors[:last_name].first.should_not be_nil
    u.errors[:last_name].first.should =~ /^is too long.*/
  end

  it "should require quota to be set" do
    user = FactoryGirl.create :tuser
    user.should be_valid

    user.quota = nil
    user.should_not be_valid
  end

  it "should encrypt password when a user is saved" do
    user = FactoryGirl.build :tuser
    user.crypted_password.should be_nil
    user.save!
    user.crypted_password.should_not be_nil
  end


  it "should authenticate a user with valid password" do
    user = FactoryGirl.create :tuser
    User.authenticate(user.username, user.password, user.last_login_ip).should_not be_nil
  end

  it "should not authenticate a user with valid password" do
    user = FactoryGirl.create :tuser
    User.authenticate(user.username, 'invalid', user.last_login_ip).should be_nil
  end

  it "should authenticate a user against LDAP and create local user w/o password" do
    Ldap.should_receive(:valid_ldap_authentication?).and_return(true)
    User.authenticate_using_ldap('ldapuser', 'random', '192.168.1.1').should_not be_nil
    u = User.find_by_username('ldapuser')
    u.should_not be_nil
    u.crypted_password.should be_nil
  end

  it "should authenticate a user against LDAP and return existing user" do
    user = FactoryGirl.create(:tuser, :ignore_password => true, :password => nil)
    Ldap.should_receive(:valid_ldap_authentication?).and_return(true)
    u = User.authenticate_using_ldap(user.username, 'random', user.last_login_ip)
    u.should_not be_nil
    u.id.should == user.id
  end

  it "should authenticate a user with valid kerberos ticket" do
    User.authenticate_using_krb('krbuser', '192.168.1.1').should_not be_nil
    u = User.find_by_username('krbuser')
    u.should_not be_nil
    u.crypted_password.should be_nil
  end

  it "should reject destroy when user has running instances" do
    user = Factory.create(:tuser)
    deployment = Factory.create(:deployment, :owner => user)
    instance = Factory.create(:mock_running_instance, :deployment_id => deployment.id)
    lambda { user.destroy }.should raise_error(RuntimeError, "#{user.username} has running instances")
    user.entity.should_not be_destroyed
  end

end
