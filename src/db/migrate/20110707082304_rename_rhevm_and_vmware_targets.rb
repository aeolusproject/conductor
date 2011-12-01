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

class RenameRhevmAndVmwareTargets < ActiveRecord::Migration

  def self.up
    rename_type("rhev-m", "rhevm")
    rename_type("vmware", "vsphere")
  end

  def self.down
    rename_type("rhevm", "rhev-m")
    rename_type("vsphere", "vmware")
  end

  def self.rename_type(old, new)
    type = ProviderType.find_by_codename(old)
    if type
      type.codename = new
      type.save
    end
  end

end
