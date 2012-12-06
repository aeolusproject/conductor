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
# Table name: instance_hwps
#
#  id           :integer         not null, primary key
#  memory       :string(255)
#  cpu          :string(255)
#  architecture :string(255)
#  storage      :string(255)
#  lock_version :integer         default(0)
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
#
class InstanceHwp < ActiveRecord::Base
  has_one :instance
  belongs_to :hardware_profile

  attr_accessible :storage, :memory, :cpu, :architecture, :hardware_profile
end
