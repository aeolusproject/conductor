require 'spec_helper'

describe TemplatesController do

  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    @tuser = Factory :tuser
    activate_authlogic
  end

  it "should allow a user with image_modify permission to create new template" do
     UserSession.create(@admin)
     lambda do
       post :create, :tpl => { :name => 'template', :platform => 'fedora', :platform_version => '11', :architecture => '64-bit' }
     end.should change(Template, :count).by(1)
     response.should redirect_to(templates_path)
  end

  it "should deny access to new template ui without image modify permission" do
    UserSession.create(@tuser)
    get :new
    response.should_not render_template("new")
  end

  context "when a user has permission to build templates" do
    #FIXME: The following functionality needs to come out of the controller

    before(:each) do
      UserSession.create(@admin)
      @template = Factory.create(:template)
    end

    it "should create a new Image" do
      lambda do
        post :build, :image => {:template_id => @template.id}, :targets => ["mock"]
      end.should change(Image, :count).by(1)
    end

    it "should create a new ReplicatedImage" do
      mock = Factory.create(:mock_provider)
      lambda do
        post :build, :image => {:template_id => @template.id}, :targets => ["mock"]
      end.should change(ReplicatedImage, :count).by(1)
    end
  end
end
