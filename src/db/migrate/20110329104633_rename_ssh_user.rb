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

class RenameSshUser < ActiveRecord::Migration
  def self.up
    pt = ProviderType.first(:conditions => {:codename => 'ec2'})
    if pt
      pt.ssh_user = 'root'
      pt.home_dir = '/root'
      pt.save!
    end
  end

  def self.down
    pt = ProviderType.first(:conditions => {:codename => 'ec2'})
    if pt
      pt.ssh_user = 'ec2-user'
      pt.home_dir = '/home/ec2-user'
      pt.save!
    end
  end
end
