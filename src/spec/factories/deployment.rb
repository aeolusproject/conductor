#
#   Copyright 2011 Red Hat, Inc.
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

FactoryGirl.define do
  factory :deployment do
    sequence(:name) { |n| "deployment#{n}" }
    association :pool, :factory => :pool
    association :owner, :factory => :user
    after_build do |deployment|
      deployment.deployable_xml = DeployableXML.import_xml_from_url("http://localhost/deployables/deployable1.xml")
    end
  end
  factory :deployment_with_launch_parameters, :parent => :deployment do
    after_build do |deployment|
      deployment.deployable_xml = DeployableXML.import_xml_from_url("http://localhost/deployables/deployable_with_launch_parameters.xml")
    end
  end

  factory :deployment_with_1st_running_all_stopped, :parent => :deployment do
    after_create do |deployment|
      deployment.events << Factory.create(:event, :source => deployment, :event_time => "2012-01-20 13:33:33", :status_code => "first_running")
      deployment.events << Factory.create(:event, :source => deployment, :event_time => "2012-01-21 13:33:33", :status_code => "all_stopped")
    end
  end

  factory :deployment_with_all_running_stopped_some_stopped, :parent => :deployment do
    after_create do |deployment|
      deployment.events << Factory.create(:event, :source => deployment, :event_time => "2012-01-20 13:33:33", :status_code => "all_running")
      deployment.events << Factory.create(:event, :source => deployment, :event_time => "2012-01-20 15:33:33", :status_code => "some_stopped")
      deployment.events << Factory.create(:event, :source => deployment, :event_time => "2012-01-21 13:33:33", :status_code => "all_stopped")
    end
  end
end
