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

module DeployableMatching

  class Validator

    attr_reader :errors

    def initialize
      @errors = []
    end

    def self.errors_for_deployable(pool, user, deployable_xml)
      validator = self.new
      validator.run_deployable_level_checks(pool, user, deployable_xml)
      validator.errors
    end


    def self.errors_for_assembly(assembly, assembly_hwp)
      validator = self.new
      validator.run_assembly_level_checks(assembly, assembly_hwp)
      validator.errors
    end

    def self.errors_for_provider_account(assembly, provider_account, provider_hwp, provider_image)
      validator = self.new
      validator.run_provider_account_level_checks(assembly, provider_account, provider_hwp, provider_image)
      validator.errors
    end

    def run_deployable_level_checks(pool, user, deployable_xml)
      assembly_count = deployable_xml.assemblies.length

      if pool.pool_family.provider_accounts.empty?
        errors << I18n.t('instances.errors.no_provider_accounts')
      end

      unless pool.quota.can_start_instance_count?(assembly_count)
        errors << I18n.t('instances.errors.pool_quota_reached')
      end

      unless pool.pool_family.quota.can_start?(assembly_count)
        errors << I18n.t('instances.errors.pool_family_quota_reached')
      end

      unless user.quota.can_start?(assembly_count)
        errors << I18n.t('instances.errors.user_quota_reached')
      end
    end

    def run_assembly_level_checks(assembly, assembly_hwp)
      unless assembly_hwp
        @errors << I18n.t('deployments.flash.error.no_hwp_permission', :hwp => assembly.hwp)
      end

      if base_images_exists?(assembly)
        check_arch_mismatches(assembly, assembly_hwp)
      else
        @errors << I18n.t('instances.errors.image_not_found', :b_uuid=> assembly.image_build, :i_uuid => assembly.image_id)
      end
    end

    def base_images_exists?(assembly)
      !ImageFetcher.base_image(assembly).nil?
    end

    def check_arch_mismatches(assembly, assembly_hwp)
      return unless assembly_hwp

      image_arch = ImageFetcher.image_arch(assembly)

      if image_arch && assembly_hwp.architecture && assembly_hwp.architecture.value != image_arch
        @errors << I18n.t('instances.errors.architecture_mismatch', :inst_arch => assembly_hwp.architecture.value, :img_arch => image_arch)
      end
    end

    def run_provider_account_level_checks(assembly, provider_account, provider_hwp, provider_image)
      unless provider_account.provider.enabled?
        @errors << I18n.t('instances.errors.must_be_enabled', :account_name => provider_account.name)
      end

      unless provider_account.provider.available?
        @errors << I18n.t('instances.errors.provider_not_available', :account_name => provider_account.name)
      end

      if provider_account.quota.reached?
        @errors << I18n.t('instances.errors.provider_account_quota_reached', :account_name => provider_account.name)
      end

      unless provider_hwp
        @errors << I18n.t('instances.errors.hw_profile_match_not_found', :account_name => provider_account.name)
      end

      unless provider_image
        @errors << I18n.t('instances.errors.image_not_pushed_to_provider', :account_name => provider_account.name)
      end

      if assembly.requires_config_server? && provider_account.config_server.nil?
        @errors << I18n.t('instances.errors.no_config_server_available', :account_name => provider_account.name)
      end
    end

  end

end
