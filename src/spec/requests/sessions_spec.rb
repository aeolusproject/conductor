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
      fill_in "username", :with => @user.login
      fill_in "password-input", :with => "secret"
      click_button "Login"
    end

    it "should be authenticated" do
      visit pools_path
      page.body.should include 'logout'
    end

    it "should have session expiration" do
      Timecop.travel(Time.now + (SETTINGS_CONFIG[:session][:timeout] + 1).minutes)
      visit pools_path
      page.body.should_not include 'logout'
      Timecop.return
    end

    it "should have session expiration unaffected by Backbone requests (when the expired request is Backbone)" do
      original_time = Time.now

      # Make a backbone-like request at about a half of the expiration period.
      Timecop.travel(original_time + (SETTINGS_CONFIG[:session][:timeout] / 2).minutes)
      page.driver.get(pools_path, {}, {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      })

      # Make a backbone-like request right after the expiration period.
      Timecop.travel(original_time + (SETTINGS_CONFIG[:session][:timeout] + 1).minutes)
      page.driver.get(pools_path, {}, {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      })

      # Check that the first request didn't extend the expiration period and
      # the session is now expired.
      page.body.should_not include 'logout'
      Timecop.return
    end

    it "should have session expiration unaffected by Backbone requests (when the expired request is normal)" do
      original_time = Time.now

      # Make a backbone-like request at about a half of the expiration period.
      Timecop.travel(original_time + (SETTINGS_CONFIG[:session][:timeout] / 2).minutes)
      page.driver.get(pools_path, {}, {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      })

      # Make a normal request right after the expiration period.
      Timecop.travel(original_time + (SETTINGS_CONFIG[:session][:timeout] + 1).minutes)
      visit pools_path

      # Check that the first request didn't extend the expiration period and
      # the session is now expired.
      page.body.should_not include 'logout'
      Timecop.return
    end
  end
end
