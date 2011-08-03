require 'spec_helper'

describe ProvidersHelper do
  include ProvidersHelper

  context "edit_button() helper" do

    it "formats link with path to edit action if rendered in show or accounts action" do
      provider = FactoryGirl.create(:mock_provider)

      edit_button(provider, 'show').should =~ /providers\/[0-9]*\/edit/
    end

    it "formats blank link with no action and with disabled class if not in show or accounts action" do
      provider = FactoryGirl.create(:mock_provider)

      edit_button = edit_button(provider, 'index')
      edit_button.should =~ /href="#"/
      edit_button.should =~ /disabled/
    end

  end

end
