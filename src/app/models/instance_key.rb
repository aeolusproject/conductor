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
# Table name: instance_keys
#
#  id          :integer         not null, primary key
#  instance_id :integer         not null
#  name        :string(255)     not null
#  pem         :text
#  created_at  :datetime
#  updated_at  :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
#

class InstanceKey < ActiveRecord::Base
  belongs_to :instance
  before_destroy :destroy_instance_key

  def destroy_instance_key
    begin
      instance.provider_account.connect.key(self.name).destroy!
    rescue
      Rails.logger.error "failed to destroy instance key #{self.name} of instance #{instance.name}: #{$!.message}"
    end
    true
  end
end
