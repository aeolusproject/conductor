#
#   Copyright 2013 Red Hat, Inc.
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

Alberich::Entity.class_eval do
  class << self
    include CommonFilterMethods
  end

  PRESET_FILTERS_OPTIONS = [
    {:title => "user",
     :id => "users",
     :where => {"alberich_entities.entity_target_type" => "User"}},
    {:title => "user_group",
     :id => "user_groups",
     :where => {"alberich_entities.entity_target_type" => "UserGroup"}}
  ]

  def self.apply_search_filter(search)
    return scoped unless search
    where("lower(alberich_entities.name) LIKE :search", :search => "%#{search.downcase}%")
  end

end
