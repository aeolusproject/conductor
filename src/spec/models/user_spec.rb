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

  it "should require unique login" do
    user1 = Factory.create(:tuser)
    user2 = Factory.create(:tuser)
    user1.should be_valid
    user2.should be_valid

    user2.login = user1.login
    user2.should_not be_valid
  end

  it "should require unique email" do
    user1 = Factory.create(:tuser)
    user2 = Factory.create(:tuser)
    user1.should be_valid
    user2.should be_valid

    user2.email = user1.email
    user2.should_not be_valid
  end

  it "should requive valid email" do
    user = User.new(Factory.attributes_for(:tuser))

    user.email = "invalid-email"
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

end
