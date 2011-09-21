#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

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
        @deployment = Factory.build(:deployment)
        Deployment.stub!(:new).and_return(@deployment)
        post :create
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
