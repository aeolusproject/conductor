#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

FactoryGirl.define do
  factory :catalog_entry do
    sequence(:name) { |n| "catalog_entry#{n}" }
    xml "<?xml version=\"1.0\"?>
            <deployable name='my'>
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
    description "catalog entry description"
    association :catalog, :factory => :catalog
    association :owner, :factory => :user
  end

  factory :catalog_entry_with_parameters, :parent => :catalog_entry do
    xml "<?xml version=\"1.0\"?>
            <deployable name='deployable_with_launch_parameters'>
              <description>A Deployable with launch parameters</description>
                <assemblies>
                  <assembly name='assembly_with_launch_parameters' hwp='front_hwp1'>
                    <image id='34c87aa0-3405-42f8-820e-309054029295'/>
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
