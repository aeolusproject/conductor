require 'spec_helper'

describe ProvidersController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :provider_admin_permission
    @provider = @admin_permission.permission_object
    @admin = @admin_permission.user
    mock_warden(@admin)
  end

  describe "provide ui to view hardware profiles" do
    before do
      get :show, :id => @provider.id, :details_tab => 'hw_profiles', :format => :js
    end

    it { response.should render_template(:partial => 'providers/_hw_profiles') }
    it { response.should be_success }
    it { assigns[:hardware_profiles].size.should == @provider.hardware_profiles.size }
  end

  describe "provide ui to view realms" do
    before do
      get :show, :id => @provider.id, :details_tab => 'realms', :format => :js
    end

    it { response.should be_success }
    it { assigns[:realm_names].size.should == @provider.realms.size }
    it { response.should render_template(:partial => "providers/_realms") }
  end
end
