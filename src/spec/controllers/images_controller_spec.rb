#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'spec_helper'

describe ImagesController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    @provider_account = FactoryGirl.create :mock_provider_account
    @pool_family = FactoryGirl.create :pool_family
  end

  describe "#import" do

    it "strips whitespace off the image id provided by the user" do
      ProviderAccount.stub(:find).and_return(@provider_account)
      PoolFamily.stub(:find).and_return(@pool_family)
      @image = mock_model(Aeolus::Image::Factory::Image)

      Image.should_receive(:import).
            with { |provider_account, image_id, pool_family, xml| image_id == 'Mock_mock_123abc' }.
            and_return(@image)

      mock_warden(@admin)
      post(:import, :image_id => ' Mock_mock_123abc   ',
           :name => 'imported',
           :provider_account => '1',
           :environment => 'some_environment')
    end

  end
end
