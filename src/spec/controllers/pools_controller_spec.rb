#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

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
     response.should redirect_to(pools_path)
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

  context "unauthenticated JSON responses " do
    before do
      accept_json
      mock_warden(nil)
    end

    it "should return 401" do
      get :index
      response.response_code.should == 401
    end
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
        @tpool = Factory.build(:tpool)
        @pool.save!
        @tpool.save!
        Pool.stub!(:find).and_return([@pool], @tpool)
        delete :multi_destroy, :pools_selected => [@pool.id], :format => :json
      end

      it { response.should be_success }
      it { ActiveSupport::JSON.decode(response.body)["success"].should == [@pool.name] }
    end
  end
end
