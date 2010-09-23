require 'spec_helper'

describe Realm do

  before(:each) do
    @provider = Factory :mock_provider
    @backend_realm = Factory :backend_realm, :provider => @provider

    @frontend_realm = Factory :frontend_realm, :provider => nil
    @backend_realm.frontend_realms << @frontend_realm
    @frontend_realm.backend_realms << @backend_realm
  end

  it "should validate backend" do
    @backend_realm.provider_id.should_not be_nil
    @backend_realm.backend_realms.should be_empty

    @backend_realm.frontend_realms.should_not be_empty
    @backend_realm.frontend_realms.first.id.should == @frontend_realm.id
  end

  it "should validate frontend" do
    @frontend_realm.provider_id.should be_nil
    @frontend_realm.frontend_realms.should be_empty

    @frontend_realm.backend_realms.should_not be_empty
    @frontend_realm.backend_realms.first.id.should == @backend_realm.id
  end

  it "should map the frontend and backend names" do
    @frontend_realm.name = 'different_from' + @backend_realm.name
    @frontend_realm.should_not be_valid
    @backend_realm.should_not be_valid

    @frontend_realm.name = @backend_realm.name
    @frontend_realm.should be_valid
    @backend_realm.should be_valid
  end

  it "should map the frontend and backend keys" do
    @frontend_realm.external_key = 'different_from' + @backend_realm.external_key
    @frontend_realm.should_not be_valid
    @backend_realm.should_not be_valid

    @frontend_realm.external_key = @backend_realm.external_key
    @frontend_realm.should be_valid
    @backend_realm.should be_valid
  end

end
