require 'spec_helper'

describe Tim::BaseImage do

  fixtures :all

  describe ".create" do
    it_should_behave_like "an object with autgenerated uuid" do
      let(:uuid_object) { FactoryGirl.build(:base_image_with_template) }
    end
  end
end
