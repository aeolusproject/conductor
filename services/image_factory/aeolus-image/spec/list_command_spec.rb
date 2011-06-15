require 'spec_helper'

module Aeolus
  module Image
    describe ListCommand do
      it "should return a list of images" do
        regexp = Regexp.new('[uuid:\s][\w]{8}[-][\w]{4}[-][\w]{4}[-][\w]{4}[-][\w]{12}')
        listc = ListCommand.new(:subcommand => 'images')
        images = listc.images
        images.each do |image|
          regexp.match(image.to_s).should_not == nil
        end
      end

    end
  end
end