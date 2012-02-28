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

describe DeploymentsController do
  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create(:admin_permission)
    @admin = @admin_permission.user
  end

  it "should allow RESTful delete of a single deployment" do
    mock_warden(@admin)
    deployment = nil
    lambda do
      deployment = FactoryGirl.create(:deployment)
      deployment.owner = @admin
      deployment.save!
    end.should change(Deployment, :count).by(1)
    lambda do
      delete :destroy, :id => deployment.id
    end.should change(Deployment, :count).by(-1)
  end

  it "should allow multi destroy of multiple deployments" do
    mock_warden(@admin)
    deployment1 = nil
    deployment2 = nil
    lambda do
      deployment1 = FactoryGirl.create(:deployment, :owner => @admin)
      deployment1.save!
      deployment2 =  FactoryGirl.create(:deployment, :owner => @admin)
      deployment2.save!
    end.should change(Deployment, :count).by(2)
    lambda do
      post :multi_destroy, :deployments_selected => [deployment1.id, deployment2.id]
    end.should change(Deployment, :count).by(-2)
  end

  context "JSON format responses for " do
    before do
      accept_json
      mock_warden(@admin)
    end

    describe "#create" do
      before do
        Factory.create(:front_hwp1)
        Factory.create(:front_hwp2)
        @deployment = Factory.build(:deployment)
        @catalog = Factory.create(:catalog)
        @deployable = Factory.create(:deployable, :catalogs => [@catalog])
        Deployment.stub!(:new).and_return(@deployment)
        post :create, :deployable_id => @deployable.id
      end

      it { response.should be_success }
      it { ActiveSupport::JSON.decode(response.body)["name"].should == @deployment.name }
    end

    describe "#destroy" do
      before do
        @deployment = Factory.build(:deployment)
        Deployment.stub!(:find).and_return([@deployment])
        delete :multi_destroy, :deployments_selected => [@deployment.id], :format => :json
      end

      it { response.should be_success }
      it { ActiveSupport::JSON.decode(response.body)["success"].should == [@deployment.name] }
    end
  end

end
