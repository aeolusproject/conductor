require 'spec_helper'

describe CloudAccount do
  fixtures :all
  before(:each) do
    @cloud_account = Factory :mock_cloud_account
  end

  it "should not be destroyable if it has instances" do
    @cloud_account.instances << Instance.new
    @cloud_account.destroyable?.should_not be_true
    @cloud_account.destroy
    CloudAccount.find(@cloud_account.id).should_not be_nil


    @cloud_account.instances.clear
    @cloud_account.destroyable?.should be_true
    @cloud_account.destroy
    CloudAccount.find(:first, :conditions => ['id = ?', @cloud_account.id]).should be_nil
  end
end
