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

FactoryGirl.define do
  factory :template, :class => Tim::Template do
    # association :pool_family
    pool_family { PoolFamily.find_by_name('default') }
    xml "<template>
           <name>Fedora 15</name>
             <description>desc</description>
             <os>
             <rootpw>password</rootpw>
              <name>Fedora</name>
              <arch>x86_64</arch>
              <version>15</version>
              <install type='url'>
                <url>http://download.fedoraproject.org/pub/fedora/linux/releases/15/Fedora/x86_64/os/</url>
              </install>
            </os>
            <repositories>
              <repository name='custom'>
                <url>http://repos.fedorapeople.org/repos/aeolus/demo/webapp/</url>
                <signed>false</signed>
              </repository>
            </repositories>
          </template>"
  end

  factory :template_i386, :parent => :template do
    xml "<template>
           <name>Fedora 15</name>
             <description>desc</description>
             <os>
             <rootpw>password</rootpw>
              <name>Fedora</name>
              <arch>i386</arch>
              <version>15</version>
              <install type='url'>
                <url>http://download.fedoraproject.org/pub/fedora/linux/releases/15/Fedora/x86_64/os/</url>
              </install>
            </os>
            <repositories>
              <repository name='custom'>
                <url>http://repos.fedorapeople.org/repos/aeolus/demo/webapp/</url>
                <signed>false</signed>
              </repository>
            </repositories>
          </template>"
  end
end
