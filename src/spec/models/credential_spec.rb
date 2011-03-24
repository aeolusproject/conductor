require "spec_helper"

describe Credential do
  before(:each) do
    @credential = Factory.build(:credential)
  end

  it "default factory object is valid" do
    @credential.should be_valid
  end

  it "should not be valid without value" do
    @credential.value = nil
    @credential.should_not be_valid
  end

  it "should not be valid without assigned credential definition" do
    @credential.credential_definition_id = nil
    @credential.should_not be_valid
  end

  it "should not be valid without unique credential definition" do
    @credential.save!
    @second_credential = Factory.build(:credential,
                                       :credential_definition_id => @credential.credential_definition_id,
                                       :provider_account_id => @credential.provider_account_id)
    @second_credential.should_not be_valid
  end
end
