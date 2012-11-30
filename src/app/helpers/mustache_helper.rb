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

  def user_info_for_mustache
    user_pools = Pool.list_for_user(current_session, current_user,
                                    Privilege::CREATE, Deployment);
    user_instances = current_user.owned_instances
    user_available_quota = current_user.quota.maximum_running_instances
    {
      :user_pools_count  => user_pools.count,
      :pools_in_use      => user_pools.select {
        |pool| pool.instances.pending_or_deployed.count > 0
      }.count,
      :deployments_count => current_user.deployments.count,
      :instances_count   => user_instances.count,
      :instances_pending_count => user_instances.pending.count,
      :instances_failed_count  => user_instances.failed.count,
      :percentage_quota  => number_to_percentage(current_user.quota.percentage_used,
                                                 :precision => 0),
      :user_running_instances  => current_user.quota.running_instances,
      :user_available_quota    => user_available_quota.nil? ? raw('&infin;') : user_available_quota
    }
  end

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
      :last_error           => instance.last_error,
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
      :state                => deployment.state,
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
    user_can_access_pool_family =
      check_privilege(Privilege::VIEW, pool.pool_family)

    {
      :id               => pool.id,
      :name             => pool.name,
      :view_path => pool_path(pool),
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
      },

      :user_deployments => paginate_collection(pool.deployments.
                                               list_for_user(current_session,
                                                             current_user,
                                                             Privilege::VIEW).
                                               ascending_by_name, params[:page],
                                               PER_PAGE).map{ |deployment| deployment_for_mustache(deployment) }

    }
  end

  def image_for_mustache(image)
    last_rebuild = I18n.l(Time.at(image.last_built_image_version.created_at.to_f)) rescue ''

    result = {
      :id   => image.id,
      :name => image.imported? ? "#{image.name} (Imported)" : image.name,
      :path => tim.base_image_path(image.id),
      # TODO: we will have to parse this from template xml
      #:os_name      => image.os.name.empty? ? "N/A" : image.os.name,
      #:os_version   => image.os.version.empty? ? "N/A" : image.os.version,
      #:architecture => image.architecture.blank? ? "N/A" : image.architecture,
      #:last_rebuild => last_rebuild
      :environment => {
        :name => image.pool_family.name,
        :path => main_app.pool_family_path(image.pool_family, :details_tab => 'images')
      }
    }

    result
  end

  def old_image_builds_for_mustache(base_image)
    retval = []
    base_image.each_pair do |target,target_images|
      timg_hash = {:target => target, :combined_images => []} 
      target_images.each do |timg|
        timg_hash[:combined_images] << {:target_image => timg, 
                                         :provider_images => timg.provider_images}
      end
      retval << timg_hash
    end
    retval
  end

  def new_image_builds_for_mustache(base_image)
    retval = []
    base_image.each_pair do |prov_acct_name,prov_img_data|
      # Maybe we need to reimagine what we're even displaying here...
    end
    retval
  end

  # This should obviously be removed...
  def image_builds_for_mustache(base_image)
    old_image_builds_for_mustache(base_image)
  end



end
