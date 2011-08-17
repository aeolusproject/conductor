require 'spec_helper'

describe DeploymentsController do
  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create(:admin_permission)
    @admin = @admin_permission.user
    activate_authlogic
  end

  it "should allow RESTful delete of a single deployment" do
    UserSession.create(@admin)
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
    UserSession.create(@admin)
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

end
