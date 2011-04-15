require 'spec_helper'

describe Resources::PoolsController do
  fixtures :all
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
       post :create, :pool => {
         :name => 'foopool',
         :pool_family_id => PoolFamily.find_by_name('default').id
       }
     end.should change(Pool, :count).by(1)
     id = Pool.find(:first, :conditions => ['name = ?', 'foopool']).id
     response.should redirect_to(resources_pool_path(id))
  end

end
