require 'spec_helper'

context CredentialDefinition do
  before(:each) do
    @cred_def = Factory.build(:credential_definition)
  end

  it "default factory object should be valid" do
    @cred_def.should be_valid
  end


  it "should not be valid without name" do
    @cred_def.name = nil
    @cred_def.should_not be_valid
  end

  it "should not be valid without label" do
    @cred_def.label = nil
    @cred_def.should_not be_valid
  end

end
