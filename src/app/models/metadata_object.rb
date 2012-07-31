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
# Schema version: 20110207110131
#
# Table name: metadata_objects
#
#  id           :integer         not null, primary key
#  key          :string(255)     not null
#  value        :string(255)     not null
#  object_type  :string(255)
#  lock_version :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class MetadataObject < ActiveRecord::Base

  validates_presence_of :key
  validates_uniqueness_of :key

  validates_presence_of :value

  def self.lookup(key)
    metadata_obj = self.find_by_key(key)
    if metadata_obj.nil?
      nil
    elsif metadata_obj.object_type and !metadata_obj.object_type.empty?
      klass = ActiveRecord::Base.send(:subclasses).find{|c| c.name == metadata_obj.object_type }
      klass.find(metadata_obj.value)
    else
      metadata_obj.value
    end
  end

  def self.set(key, value)
    metadata_obj = self.find_by_key(key)
    metadata_obj = self.new(:key => key) unless metadata_obj

    if value.is_a?(ActiveRecord::Base)
      metadata_obj.object_type = value.class.to_s
      metadata_obj.value = value.id
    else
      metadata_obj.value = value
      metadata_obj.object_type = nil
    end
    metadata_obj.save!
    metadata_obj
  end

  def self.remove(key)
    metadata_obj = self.find_by_key(key)
    metadata_obj.destroy if metadata_obj
  end

end
