require 'spec_helper'

describe PoolFamiliesController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    @user_permission = FactoryGirl.create :pool_user_permission
    @user = @user_permission.user
    activate_authlogic
  end

  it "should allow authorized users to create pool family" do
    UserSession.create(@admin)
    lambda do
     post :create, :pool_family => {
       :name => 'test',
       :quota_attributes => { :maximum_running_instances => nil },
     }
    end.should change(PoolFamily, :count).by(1)
    PoolFamily.find_by_name('test').should_not be_nil
    response.should redirect_to(pool_families_path)
  end

  it "should prevent unauthorized users from creating pool families" do
    UserSession.create(@user)
    lambda do
     post :create, :pool_family => {
       :name => 'test',
       :quota_attributes => { :maximum_running_instances => nil },
     }
    end.should_not change(PoolFamily, :count)
    response.should render_template('layouts/error')
  end

  it "should allow authorized users to edit pool family" do
    pool_family = FactoryGirl.create :pool_family
    UserSession.create(@admin)
    put :update, :id => pool_family.id, :pool_family => {
      :name => 'updated pool family',
      :quota_attributes => { :maximum_running_instances => 10 },
    }
    PoolFamily.find_by_name('updated pool family').should_not be_nil
    response.should redirect_to(pool_families_path)
  end

  it "should prevent unauthorized users from creating pool families" do
    pool_family = FactoryGirl.create :pool_family
    UserSession.create(@user)
    put :update, :id => pool_family.id, :pool_family => {
      :name => 'updated pool family',
      :quota_attributes => { :maximum_running_instances => 10 },
    }
    PoolFamily.find_by_name('updated pool family').should be_nil
    response.should render_template('layouts/error')
  end
end
