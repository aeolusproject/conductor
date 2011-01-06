require 'spec_helper'

describe InstancesController do
  fixtures :all
  before(:each) do
    @admin_permission = Factory :admin_permission
    @admin = @admin_permission.user
    activate_authlogic
  end

  it "should provide ui to create new instance" do
     UserSession.create(@admin)
     get :new
     response.should be_success
     response.should render_template("new")
  end

  it "should fail to grant access to new pool ui for unauthenticated user" do
     get :new
     response.should_not be_success
  end

  it "should allow pool user to launch instance" do
     @pool_user_permission = Factory :pool_user_permission
     @pool_user = @pool_user_permission.user
     UserSession.create(@pool_user)
     pool = Permission.first(:conditions => {:permission_object_type => 'Pool', :user_id => @pool_user.id}).permission_object
     template = Factory.build(:template)
     template.save!
     hwp = Factory.build(:mock_hwp1)
     hwp.save!
     lambda do
       post :create, :instance => { :name => 'mockinstance',
                                    :pool_id => pool.id,
                                    :template_id => template.id,
                                    :hardware_profile_id => hwp.id }
     end.should change(Instance, :count).by(1)
     inst = Instance.find(:first, :conditions => ['name = ?', 'mockinstance'])
     inst.owner_id.should == @pool_user.id
  end
end
