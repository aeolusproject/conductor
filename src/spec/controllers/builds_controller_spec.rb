require 'spec_helper'

describe BuildsController do
  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    @tuser = Factory :tuser
    activate_authlogic
  end

  it "update_status should change image status" do
    UserSession.create(@tuser)
    @template = Factory.create(:legacy_template)
    @image = Factory.create(:legacy_image)
    @request.env["HTTP_ACCEPT"] = "application/xml"

    @image.status.should == "queued"
    post :update_status, :uuid => @image.uuid, :status => 'building'
    @image.reload.status.should == "building"
    response.should be_success
  end

  it "update_status should change provider image status" do
    UserSession.create(@tuser)
    @provider = Factory.create(:mock_provider)
    @template = Factory.create(:legacy_template)
    @image = Factory.create(:legacy_image)
    @provider_image = Factory.create(:mock_provider_image)
    @request.env["HTTP_ACCEPT"] = "application/xml"

    @provider_image.status.should == "completed"
    post :update_status, :uuid => @provider_image.uuid, :status => 'failed'
    @provider_image.reload.status.should == "failed"
    response.should be_success
  end

  context "when a user has permission to build legacy_templates" do
    #FIXME: The following functionality needs to come out of the controller

    before(:each) do
      UserSession.create(@admin)
      @template = Factory.create(:legacy_template)
      hydra = Typhoeus::Hydra.hydra
      hydra.stub(:put, %r{http://localhost:9090/legacy_templates/.*}).and_return(
        Typhoeus::Response.new(:code => 200))
      Factory.create(:mock_provider_account)
      Factory.create(:mock_provider)
    end

    it "should create a new LegacyImage" do
      lambda do
        post :create, :legacy_template_id => @template.id, :target => ProviderType.find_by_codename("mock").id
      end.should change(LegacyImage, :count).by(1)
    end

    it "retry build should update LegacyImage status" do
      lambda do
        post :create, :legacy_template_id => @template.id, :target => ProviderType.find_by_codename("mock").id
      end.should change(LegacyImage, :count).by(1)
      @template.legacy_images.size.should == 1
      image = @template.legacy_images[0]
      image.reload.status.should == "queued"
      post :update_status, :uuid => image.uuid, :status => 'failed'
      image.reload.status.should == "failed"
      post :retry, :legacy_image_id => image.id, :legacy_template_id => @template.id
      image.reload.status.should == "queued"

    end
  end
end
