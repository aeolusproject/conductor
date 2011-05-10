require 'spec_helper'

describe DeploymentsController do
  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    activate_authlogic
  end

  it "should allow RESTful delete of a single deployment" do
    UserSession.create(@admin)
    deployment = nil
    lambda do
      deployment = Factory(:deployment)
      deployment.owner = @admin
      deployment.save!
    end.should change(Deployment, :count).by(1)
    lambda do
      delete :destroy, :id => deployment.id
    end.should change(Deployment, :count).by(-1)
  end

  it "should allow RESTful delete of multiple deployments" do
    UserSession.create(@admin)
    deployment1 = nil
    deployment2 = nil
    lambda do
      deployment1 = Factory(:deployment, :owner => @admin)
      deployment1.save!
      deployment2 =  Factory(:deployment, :owner => @admin)
      deployment2.save!
    end.should change(Deployment, :count).by(2)
    lambda do
      delete :destroy, :ids => [deployment1.id, deployment2.id]
    end.should change(Deployment, :count).by(-2)
  end

end