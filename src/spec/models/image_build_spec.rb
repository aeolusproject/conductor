require 'spec_helper'

describe ImageBuild do
  before do
    create_test_iwhd_data_for("builds")
  end

  describe "all" do
    it "should containt testing object" do
      ImageBuild.all.collect {|i| i.uuid == "builds_testing_uuid"}.should be_true
    end
  end

  describe "find" do
    it "should containt testing object" do
      ImageBuild.find('builds_testing_uuid').uuid.should == "builds_testing_uuid"
    end

    it "should return nil" do
      ImageBuild.find('give_me_nil').should == nil
    end
  end
end