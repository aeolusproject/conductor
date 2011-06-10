require 'spec_helper'

describe Image do
  describe "all" do
    it "should contain testing object" do
      Image.all.select {|i| i.uuid == "53d2a281-448b-4872-b1b0-680edaad5922"}.size.should == 1
    end
  end

  describe "find" do
    it "should containt testing object" do
      Image.find("53d2a281-448b-4872-b1b0-680edaad5922").uuid.should == "53d2a281-448b-4872-b1b0-680edaad5922"
    end

    it "should return nil" do
      Image.find('give_me_nil').should == nil
    end
  end

  describe "latest build" do
    it "should return build list" do
      Image.find("53d2a281-448b-4872-b1b0-680edaad5922").image_builds.should include \
        ImageBuild.find("63838705-8608-44c6-aded-7c243137172c")
    end

    it "should return latest build" do
      Image.find("53d2a281-448b-4872-b1b0-680edaad5922").latest_build.should ==
        ImageBuild.find("63838705-8608-44c6-aded-7c243137172c")
    end
  end
end
