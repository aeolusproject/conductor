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
       post :new, :xml => { :name => 'fooimg', :platform => 'fedora' }, :next => true
     end.should change(Template, :count).by(1)
     id = Template.find(:first, :order => 'created_at DESC').id
     response.should redirect_to("http://test.host/templates/services/#{id}")
  end

  it "should allow a user with image_modify permission to add service" do
     UserSession.create(@admin)
     tpl = Template.new(:xml => '')
     lambda do
       tpl.save!
     end.should change(Template, :count).by(1)
     post :services, :xml => { :xml => {:services => ['jboss']} }, :next => true, :id => tpl.id
     response.should redirect_to("http://test.host/templates/software/#{tpl.id}")
  end

  # FIXME: these two tests depends on jboss repository which defines 'JBoss Core
  # Packages' groups (this repository is currently only internal), uncomment
  # when repository is ready
  #
  #it "should allow a user with image_modify permission to add and remove a group" do
  #   UserSession.create(@admin)
  #   tpl = Template.new(:xml => '')
  #   lambda do
  #     tpl.save!
  #   end.should change(Template, :count).by(1)
  #   post :select_group, :id => tpl.id, :group => 'JBoss Core Packages'
  #   response.should redirect_to("http://test.host/templates/software/#{tpl.id}")
  #   post :remove_group, :id => tpl.id, :group => 'JBoss Core Packages'
  #   response.should redirect_to("http://test.host/templates/software/#{tpl.id}")
  #end

  #it "should allow a user with image_modify permission to add a package" do
  #   UserSession.create(@admin)
  #   tpl = Template.new(:xml => '')
  #   lambda do
  #     tpl.save!
  #     post :select_package, :id => tpl.id, :package => 'jboss-rails', :group => 'JBoss Core Packages'
  #   end.should change(Template, :count).by(1)
  #   response.should redirect_to("http://test.host/templates/software/#{tpl.id}")
  #end

  it "should allow a user with image_modify permission to build image descriptor" do
     UserSession.create(@admin)
     tpl = Factory :template
     lambda do
       post :summary, :id => tpl.id, :targets => ['ec2'], :build => true
     end.should change(Image, :count).by(1)
  end

  it "should deny access to new template ui without image modify permission" do
    UserSession.create(@tuser)
    %w(new services software summary).each do |tab|
      get tab.intern
      response.should_not render_template("new")
    end
  end
end
