require 'spec_helper'

describe PoolsController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
  end

  it "should provide ui to create new pool" do
     mock_warden(@admin)
     get :new
     response.should be_success
     response.should render_template("new")
  end

  it "should fail to grant access to new pool ui for unauthenticated user" do
     mock_warden(nil)
     get :new
     response.should_not be_success
  end

  it "should provide means to create new pool" do
     mock_warden(@admin)
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
    mock_warden(@admin)
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
    mock_warden(@admin)
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

  context "JSON format responses for " do
    before do
      accept_json
      mock_warden(@admin)
    end

    describe "#create" do
      before do
        @pool_attributes = Factory.attributes_for(:pool)
        post :create, :pool => @pool_attributes
      end

      it { response.should be_success }
      it { ActiveSupport::JSON.decode(response.body)["name"].should == @pool_attributes[:name] }
      it { ActiveSupport::JSON.decode(response.body)["enabled"].should == @pool_attributes[:enabled] }
    end

    describe "#destroy" do
      before do
        @pool = Factory.build(:pool)
        Pool.stub!(:find).and_return([@pool])
        delete :multi_destroy, :pools_selected => [@pool.id], :format => :json
      end

      it { response.should be_success }
      it { ActiveSupport::JSON.decode(response.body)["success"].should == [@pool.name] }
    end
  end
end
