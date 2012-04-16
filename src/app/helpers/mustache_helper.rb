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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module MustacheHelper

  def instance_for_mustache(instance)
    available_actions = instance.get_action_list

    {
      :id       => instance.id,
      :name     => instance.name,
      :path     => instance_path(instance),
      :uptime   => count_uptime(instance.uptime),
      :translated_state     => t("instances.states.#{instance.state}"),
      :public_addresses     => instance.public_addresses.present? ? instance.public_addresses : I18n.t('deployments.pretty_view_show.no_ip_address'),
      :instance_key_present => instance.instance_key.present?,
      :stop_enabled         => available_actions.include?(InstanceTask::ACTION_STOP),
      :reboot_enabled       => available_actions.include?(InstanceTask::ACTION_REBOOT),
    }
  end

end
