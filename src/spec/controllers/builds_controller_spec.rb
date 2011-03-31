require 'spec_helper'

describe ImageFactory::BuildsController do
  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    @tuser = Factory :tuser
    activate_authlogic
  end

  it "update_status should change image status" do
    UserSession.create(@tuser)
    @template = Factory.create(:template)
    @image = Factory.create(:image)
    @request.env["HTTP_ACCEPT"] = "application/xml"

    @image.status.should == "queued"
    post :update_status, :uuid => @image.uuid, :status => 'building'
    @image.reload.status.should == "building"
    response.should be_success
  end

  it "update_status should change provider image status" do
    UserSession.create(@tuser)
    @provider = Factory.create(:mock_provider)
    @template = Factory.create(:template)
    @image = Factory.create(:image)
    @provider_image = Factory.create(:mock_provider_image)
    @request.env["HTTP_ACCEPT"] = "application/xml"

    @provider_image.status.should == "completed"
    post :update_status, :uuid => @provider_image.uuid, :status => 'failed'
    @provider_image.reload.status.should == "failed"
    response.should be_success
  end

  context "when a user has permission to build templates" do
    #FIXME: The following functionality needs to come out of the controller

    before(:each) do
      UserSession.create(@admin)
      @template = Factory.create(:template)
      hydra = Typhoeus::Hydra.hydra
      hydra.stub(:put, %r{http://localhost:9090/templates/.*}).and_return(
        Typhoeus::Response.new(:code => 200))
      Factory.create(:mock_provider_account)
      Factory.create(:mock_provider)
    end

    it "should create a new Image" do
      lambda do
        post :create, :template_id => @template.id, :target => ProviderType.find_by_codename("mock").id
      end.should change(Image, :count).by(1)
    end

    it "retry build should update Image status" do
      lambda do
        post :create, :template_id => @template.id, :target => ProviderType.find_by_codename("mock").id
      end.should change(Image, :count).by(1)
      @template.images.size.should == 1
      image = @template.images[0]
      image.reload.status.should == "queued"
      post :update_status, :uuid => image.uuid, :status => 'failed'
      image.reload.status.should == "failed"
      post :retry, :image_id => image.id, :template_id => @template.id
      image.reload.status.should == "queued"

    end
  end
end
