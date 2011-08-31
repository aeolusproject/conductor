require 'spec_helper'

describe ProviderAccountsController do

  fixtures :all
  before(:each) do
    @tuser = FactoryGirl.create :tuser
    @provider_account = FactoryGirl.create :mock_provider_account
    @provider = @provider_account.provider

    @admin_permission = Permission.create :role => Role.find(:first, :conditions => ['name = ?', 'Provider Administrator']),
                                          :permission_object => @provider,
                                          :user => FactoryGirl.create(:provider_admin_user)
    @admin = @admin_permission.user
  end

  it "shows provider accounts as list" do
    mock_warden(@admin)
    get :index, :provider_id => @provider.id
    response.should be_success
    response.should render_template("index")
  end

  it "doesn't allow to save provider's account if not valid credentials" do
    mock_warden(@admin)
    post :create, :provider_account => {:provider_id => @provider.id}
    response.should be_success
    response.should render_template("new")
    response.flash[:error].should == "Cannot add the provider account."
  end

  it "should permit users with account modify permission to access edit cloud account interface" do
    mock_warden(@admin)
    get :edit, :id => @provider_account.id
    response.should be_success
    response.should render_template("edit")
  end

  it "should allow users with account modify password to update a cloud account" do
    mock_warden(@admin)
    @provider_account.credentials_hash = {:username => 'mockuser2', :password => "foobar"}
    @provider_account.stub!(:valid_credentials?).and_return(true)
    @provider_account.quota = Quota.new
    @provider_account.save.should be_true
    post :update, :id => @provider_account.id, :provider_account => { :credentials_hash => {:username => 'mockuser', :password => 'mockpassword'} }
    response.should redirect_to provider_account_path(@provider_account)
    ProviderAccount.find(@provider_account.id).credentials_hash['password'].should == "mockpassword"
  end

  it "should allow users with account modify permission to delete a cloud account" do
    mock_warden(@admin)
    lambda do
      post :multi_destroy, :accounts_selected => [@provider_account.id]
    end.should change(ProviderAccount, :count).by(-1)
    response.should redirect_to provider_accounts_url
    ProviderAccount.find_by_id(@provider_account.id).should be_nil
  end

  it "should deny access to users without account modify permission" do
    mock_warden(@tuser)
    get :edit, :id => @provider_account.id
    response.should render_template('layouts/error')

    post :update, :id => @provider_account.id, :provider_account => { :password => 'foobar' }
    response.should render_template('layouts/error')

    post :destroy, :id => @provider_account.id
    response.should render_template('layouts/error')
  end

  it "should provide ui to create new account" do
     mock_warden(@admin)
     get :new, :provider_id => @provider.id
     response.should be_success
     response.should render_template("new")
  end

  it "should fail to grant access to account UIs for unauthenticated user" do
     mock_warden(nil)
     get :new
     response.should_not be_success
  end

end
