require 'spec_helper'

describe PoolsController do

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

  it "should provide means to create new pool" do
     UserSession.create(@admin)
     lambda do
       post :create, :pool => {
         :name => 'foopool',
         :pool_family_id => PoolFamily.find_by_name('default').id,
         :enabled => true
       }
     end.should change(Pool, :count).by(1)
     id = Pool.find(:first, :conditions => ['name = ?', 'foopool']).id
     response.should redirect_to(pool_path(id))
  end

  it "should allow RESTful delete of a single pool" do
    UserSession.create(@admin)
    lambda do
      post :create, :pool => {
          :name => 'pool1',
          :pool_family_id => PoolFamily.find_by_name('default').id,
          :enabled => true
      }
    end.should change(Pool, :count).by(1)
    pool = Pool.find_by_name('pool1')
    lambda do
      delete :destroy, :id => pool.id
    end.should change(Pool, :count).by(-1)
  end

  it "should allow RESTful delete of multiple pools" do
    UserSession.create(@admin)
    lambda do
      post :create, :pool => {
          :name => 'pool1',
          :pool_family_id => PoolFamily.find_by_name('default').id,
          :enabled => true
      }
    end.should change(Pool, :count).by(1)
    lambda do
      post :create, :pool => {
          :name => 'pool2',
          :pool_family_id => PoolFamily.find_by_name('default').id,
          :enabled => true
      }
    end.should change(Pool, :count).by(1)
    pool1 = Pool.find_by_name('pool1')
    pool2 = Pool.find_by_name('pool2')
    lambda do
      delete :destroy, :ids => [pool1.id, pool2.id]
    end.should change(Pool, :count).by(-2)
  end

end
