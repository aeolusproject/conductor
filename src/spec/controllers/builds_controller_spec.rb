require 'spec_helper'

describe BuildsController do
  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    @tuser = Factory :tuser
    activate_authlogic
  end

  context "when a user has permission to build templates" do
    #FIXME: The following functionality needs to come out of the controller

    before(:each) do
      UserSession.create(@admin)
      @template = Factory.create(:template)
      hydra = Typhoeus::Hydra.hydra
      hydra.stub(:put, %r{http://localhost:9090/templates/.*}).and_return(
        Typhoeus::Response.new(:code => 200))
      Factory.create(:mock_cloud_account)
      Factory.create(:mock_provider)
    end

    it "should create a new Image" do
      lambda do
        post :create, :template_id => @template.id, :targets => ["mock"]
      end.should change(Image, :count).by(1)
    end

    it "should create a new ReplicatedImage" do
      lambda do
        post :create, :template_id => @template.id, :targets => ["mock"]
      end.should change(ReplicatedImage, :count).by(1)
    end
  end
end
