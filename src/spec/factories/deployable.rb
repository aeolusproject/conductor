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
  factory :deployable do
    sequence(:name) { |n| "deployable#{n}" }
    xml "<?xml version=\"1.0\"?>
            <deployable version='1.0' name='my'>
              <description>This is my testing image</description>
              <assemblies>
                <assembly name='frontend' hwp='front_hwp1'>
                  <image id='85653387-88b2-46b0-b7b2-c779d2af06c7' build='c5fc000b-829a-4bb5-9df1-bb228da2c7ec'></image>
                </assembly>
                <assembly name='backend' hwp='front_hwp2'>
                  <image id='85653387-88b2-46b0-b7b2-c779d2af06c7' build='c5fc000b-829a-4bb5-9df1-bb228da2c7ec'></image>
                </assembly>
              </assemblies>
            </deployable>"
    description "deployable description"
    association :owner, :factory => :user

  end

  factory :deployable_with_parameters, :parent => :deployable do
    xml "<?xml version=\"1.0\"?>
            <deployable version='1.0' name='deployable_with_launch_parameters'>
              <description>A Deployable with launch parameters</description>
                <assemblies>
                  <assembly name='assembly_with_launch_parameters' hwp='front_hwp1'>
                    <image id='85653387-88b2-46b0-b7b2-c779d2af06c7' build='c5fc000b-829a-4bb5-9df1-bb228da2c7ec'></image>
                    <services>
                      <service name='service_with_launch_parameters'>
                        <executable url='executable_url'/>
                        <files>
                          <file url='file_url'/>
                        </files>
                        <parameters>
                          <parameter name='launch_parameter_1' type='scalar'/>
                          <parameter name='launch_parameter_2' type='scalar'/>
                        </parameters>
                      </service>
                    </services>
                  </assembly>
                </assemblies>
            </deployable>"
  end
end
