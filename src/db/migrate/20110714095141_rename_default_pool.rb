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

class RenameDefaultPool < ActiveRecord::Migration
  def self.up
    if pool = Pool.find_by_name("default_pool")
      pool.update_attribute(:name,"Default")
    end
  end

  def self.down
    if pool = Pool.find_by_name("Default")
      pool.update_attribute(:name,"default_pool")
    end
  end
end
