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

class AddPoolFamilyQuota < ActiveRecord::Migration
  def self.up
    add_column :pool_families, :quota_id, :integer
    PoolFamily.all.each do |pf|
      unless pf.quota
        pf.quota = Quota.new
        pf.save!
      end
    end
  end

  def self.down
    remove_column :pool_families, :quota_id
  end
end
