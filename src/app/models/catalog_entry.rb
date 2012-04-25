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

# == Schema Information
#
# Table name: catalog_entries
#
#  id          :integer         not null, primary key
#  name        :string(1024)    not null
#  description :text            not null
#  url         :string(255)
#  owner_id    :integer
#  catalog_id  :integer         not null
#

class CatalogEntry < ActiveRecord::Base
  belongs_to :catalog
  belongs_to :deployable

  validates_presence_of :catalog
  validates_presence_of :deployable

  validates_uniqueness_of :catalog_id, :scope => [:deployable_id]

  after_destroy :destroy_deployable_if_last
  after_create :update_deployable_permissions

  def update_deployable_permissions
    deployable.update_derived_permissions_for_ancestors
  end

  def destroy_deployable_if_last
    if deployable.catalog_entries.blank?
      deployable.destroy
    else
      deployable.update_derived_permissions_for_ancestors
    end
  end

  # This probably goes away once we separate catalog entry creation from deployables
  accepts_nested_attributes_for :deployable
end
