require 'spec_helper'

describe Realm do

  before(:each) do
    @provider = Factory :mock_provider
    @backend_realm = Factory :backend_realm, :provider => @provider

    @frontend_realm1 = Factory :frontend_realm
    RealmBackendTarget.create!(:frontend_realm => @frontend_realm1, :realm_or_provider => @backend_realm)
    RealmBackendTarget.create!(:frontend_realm => @frontend_realm1, :realm_or_provider => @provider)
  end

  it "should validate backend" do
    @backend_realm.provider_id.should_not be_nil
    @backend_realm.frontend_realms.should_not be_empty
    @backend_realm.frontend_realms.first.id.should == @frontend_realm1.id
    @provider.frontend_realms.should_not be_empty
    @provider.frontend_realms.first.id.should == @frontend_realm1.id
  end

  it "should validate frontend" do
    @frontend_realm1.backend_realms.should_not be_empty
    @frontend_realm1.backend_realms.first.id.should == @backend_realm.id
    @frontend_realm1.backend_providers.should_not be_nil
    @frontend_realm1.backend_providers.first.id.should == @provider.id
  end

end
