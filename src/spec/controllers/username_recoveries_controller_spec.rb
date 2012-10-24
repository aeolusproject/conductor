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

describe UsernameRecoveriesController do
  fixtures :all
  before(:each) do
    @tuser = FactoryGirl.create :tuser
    mock_warden(nil)
    Delayed::Worker.delay_jobs = false
  end

  describe "#create" do
    before (:each) do
      User.stub_chain(:find_all_by_email, :map).and_return([@tuser.id])
      UserMailer.stub(:delay).and_return(UserMailer)
      UserMailer.stub(:send_usernames)
    end

    it "should send an email with usernames related to user email" do
      UserMailer.should_receive(:send_usernames)
      post :create, :email => @tuser.email
      response.should redirect_to(login_path)
    end
  end
end
