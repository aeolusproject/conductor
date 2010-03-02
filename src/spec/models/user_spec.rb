require 'spec_helper'

describe User do
  before(:each) do
    @valid_attributes = {
    }
  end

  it "should create a new user 'tuser'" do
    Factory.create(:tuser)
  end
end
