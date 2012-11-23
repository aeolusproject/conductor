require 'spec_helper'

describe Tim::ImageVersion do

  fixtures :all

  describe ".create" do
    it_should_behave_like "an object with autgenerated uuid" do
      let(:uuid_object) { FactoryGirl.build(:image_version) }
    end
  end
end
