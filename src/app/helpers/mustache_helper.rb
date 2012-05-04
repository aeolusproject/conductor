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
      :failed   => instance.failed?,
      :translated_state     => t("instances.states.#{instance.state}"),
      :public_addresses     => instance.public_addresses.present? ? instance.public_addresses : I18n.t('deployments.pretty_view_show.no_ip_address'),
      :instance_key_present => instance.instance_key.present?,
      :stop_enabled         => available_actions.include?(InstanceTask::ACTION_STOP),
      :reboot_enabled       => available_actions.include?(InstanceTask::ACTION_REBOOT),
      :owner                => instance.owner.present? ? instance.owner.name : nil,

      :provider => {
        :name => instance.provider_account.present? ? instance.provider_account.provider.name : nil
      }
    }
  end

  def deployment_for_mustache(deployment)
    {
      :id                   => deployment.id,
      :name                 => deployment.name,
      :path                 => deployment_path(deployment),
      :filter_view_path     => deployment_path(deployment, :view => :filter),
      :status               => deployment.state,
      :translated_state     => I18n.t("deployments.status_description.#{deployment.state}"),
      :uptime               => count_uptime(deployment.uptime_1st_instance),
      :deployable_xml_name  => deployment.deployable_xml.name,
      :created_at           => deployment.created_at.to_s,
      :instances_count      => deployment.instances.count,
      :instances_count_text => I18n.t('instances.instances', :count => deployment.instances.count.to_i),
      :owner                => deployment.owner.present? ? deployment.owner.name : nil,
      :failed_instances_present => deployment.failed_instances.count > 0,
      :provider => {
        :path => deployment.provider.present? ? provider_path(deployment.provider) : nil,
        :provider_type => {
          :name => deployment.provider.present? ? deployment.provider.provider_type.name : nil,
        }
      },
      :pool => {
        :name                => deployment.pool.name,
        :filter_view_path    => pool_path(deployment.pool, :view => :filter),
      }
    }
  end

  def pool_for_mustache(pool)
    pool_statistics = pool.statistics
    user_can_access_pool_family = check_privilege(Privilege::VIEW, pool.pool_family)

    {
      :id               => pool.id,
      :name             => pool.name,
      :filter_view_path => pool_path(pool, :view => :filter),
      :failed_instances_present => pool_statistics[:instances_failed_count] > 0,
      :deployments_count        => pool.deployments.count,

      :statistics => {
        :total_instances        => pool_statistics[:total_instances],
        :instances_pending      => pool_statistics[:instances_pending],
        :instances_failed_count => pool_statistics[:instances_failed_count],
        :quota_percent          => pool_statistics[:quota_percent],
      },

      :user_can_access_pool_family => user_can_access_pool_family,
      :pool_family => {
        :name => pool.pool_family.name,
        :path => user_can_access_pool_family ? pool_family_path(pool.pool_family) : nil
      }
    }
  end

end
