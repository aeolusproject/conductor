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

describe "Deployments API" do
  shared_examples_for "listing deployments in XML" do
    subject { Nokogiri::XML(response.body) }

    context "number of deployments" do
      it { subject.xpath("/deployments/deployment").size.should == deployments.size }
    end

    context "deployment elements data" do
      it "is printed correctly" do
        deployments.each do |deployment|
          xml_deployment = subject.xpath("/deployments/deployment[@id=\"#{deployment.id}\"]")
          xml_deployment.size.should == 1
        end
      end
    end
  end

  let(:headers) { {
    'HTTP_ACCEPT' => 'application/xml',
    'CONTENT_TYPE' => 'application/xml'
  } }

  before :each do
    @user = FactoryGirl.create(:admin_permission).user
    login_as(@user)
  end

  describe "GET /api/deployments" do
    let!(:deployments) {
      deployments = []
      2.times { deployments << Factory.create(:deployment, {:pool => Pool.first, :owner => @user}) }
      deployments
    }

    before :each do
      get '/api/deployments', nil, headers
    end

    it_behaves_like "http OK"
    it_behaves_like "responding with XML"
    it_behaves_like "listing deployments in XML"
  end
end
