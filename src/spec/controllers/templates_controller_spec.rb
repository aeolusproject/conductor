require 'spec_helper'

describe TemplatesController do

  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    @tuser = Factory :tuser
    activate_authlogic
  end

  it "should deny access to new template ui without image modify permission" do
    UserSession.create(@tuser)
    get :new
    response.should_not render_template("new")
  end
end
