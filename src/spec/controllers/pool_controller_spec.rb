require 'spec_helper'

describe PoolController do

  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    activate_authlogic
  end

  it "should provide ui to create new pool" do
     UserSession.create(@admin)
     get :new
     response.should be_success
     response.should render_template("new")
  end

  it "should fail to grant access to new pool ui for unauthenticated user" do
     get :new
     response.should_not be_success
  end

  it "should provider means to create new pool" do
     UserSession.create(@admin)
     lambda do
       post :create, :pool => { :name => 'foopool' }
     end.should change(Pool, :count).by(1)
     id = Pool.find(:first, :conditions => ['name = ?', 'foopool']).id
     response.should redirect_to("http://test.host/pool/show/#{id}")
  end

  it "should provide ui to view hardware profiles" do
     UserSession.create(@admin)
     pool = Factory :tpool

     get :hardware_profiles, :id => pool.id
     response.should be_success
     assigns[:hardware_profiles].size.should == pool.hardware_profiles.size
     response.should render_template("hardware_profiles")
  end

  it "should get cloud accounts" do
     @pool  = Factory :tpool
     UserSession.create(@admin)
     get :accounts, :id => @pool.id
     response.should be_success
     response.should render_template("accounts")
     @pool.should_not == nil
  end

  it "should provide ui to view realms" do
     UserSession.create(@admin)
     pool = Factory :tpool

     get :realms, :id => pool.id
     response.should be_success
     assigns[:realm_names].size.should == pool.realms.size
     response.should render_template("realms")
  end

end
