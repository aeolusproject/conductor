require 'spec_helper'

describe "Sessions" do
  describe "User not logged in" do

    it "should not be authenticated" do
      get pools_path
      response.status.should be(302)
    end
  end

  describe "User logged in" do
    before do
      @user = FactoryGirl.create :tuser
      visit root_path
      fill_in "Username", :with => @user.login
      fill_in "password-input", :with => "secret"
      click_button "Login"
    end

    it "should be authenticated" do
      page.status_code.should be(200)
    end

    it "should have expired session" do
      visit pools_path
      Timecop.travel(Time.now+16.minutes)
      visit pools_path
      page.body.should include "#login"
      Timecop.return
    end

    end
end
