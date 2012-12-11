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

# This migration comes from tim (originally 20120911202321)
class CreateTimTargetImages < ActiveRecord::Migration
  def change
    create_table :tim_target_images do |t|
      t.string :factory_id
      t.integer :image_version_id
      t.string :target
      t.string :status
      t.string :status_detail
      t.string :progress # Factory Target Image percent_complete

      t.timestamps
    end
  end
end
