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

  class AssemblyMatchesBuilder

    attr_reader :assembly_matches
    attr_reader :errors

    def initialize(assembly_instance, provider_accounts, frontend_realm = nil, instance = nil)
      @assembly_instance = assembly_instance
      @provider_accounts = provider_accounts
      @frontend_realm = frontend_realm
      @instance = instance
    end

    def self.build(assembly_instance, provider_accounts, frontend_realm = nil, instance = nil)
      builder = self.new(assembly_instance, provider_accounts, frontend_realm, instance)
      builder.build_assembly_match

      builder
    end

    def build_assembly_match
      @assembly_matches = []
      assembly_level_warnings = []
      @errors = []

      @provider_accounts.each do |provider_account|
        provider_hwp = HardwareProfile.match_provider_hardware_profile(provider_account.provider, @assembly_instance.attributes[:hardware_profile])
        provider_image = ImageFetcher.provider_image(@assembly_instance.assembly, provider_account)

        provider_account_errors = Validator.errors_for_provider_account(@assembly_instance.assembly, provider_account, provider_hwp, provider_image)
        if provider_account_errors.any?
          assembly_level_warnings += provider_account_errors
          next
        end

        if @frontend_realm
          backend_realms = collect_backend_realms(provider_account, @frontend_realm)

          if backend_realms.empty?
            assembly_level_warnings << I18n.t('instances.errors.realm_not_mapped', :account_name => provider_account.name, :frontend_realm_name => @frontend_realm.name)
            next
          end

          backend_realms.each do |backend_realm|
            @assembly_matches << AssemblyMatch.new(provider_account,
                                                   provider_image,
                                                   @assembly_instance.attributes[:hardware_profile],
                                                   provider_hwp,
                                                   backend_realm.target_realm,
                                                   @instance)
          end
        else
          @assembly_matches << AssemblyMatch.new(provider_account,
                                                 provider_image,
                                                 @assembly_instance.attributes[:hardware_profile],
                                                 provider_hwp,
                                                 nil,
                                                 @instance)
        end
      end

      # if no match is found then escalate assembly level warnings as errors
      if @assembly_matches.any?
        filter_already_launched_matches
      else
        @errors += assembly_level_warnings
        nil
      end
    end

    private

    def collect_backend_realms(provider_account, frontend_realm)
      # add match if realm is mapped to provider or if it's mapped to
      # backend realm which is available and is accessible for this
      # provider account
      frontend_realm.realm_backend_targets.select do |backend_realm_target|
        backend_realm_target.target_provider == provider_account.provider &&
          backend_realm_target.target_realm.nil? ||
          (backend_realm_target.target_realm.available &&
            provider_account.provider_realms.include?(backend_realm_target.target_realm))
      end
    end

    def filter_already_launched_matches
      @assembly_matches = @assembly_matches.delete_if do |match|
        return false if match.instance.nil?

        search_params = {
          :provider_account_id => match.provider_account.id,
          :hardware_profile_id => match.provider_hwp.id,
          :provider_image => match.provider_image.external_image_id
        }
        search_params[:provider_realm_id] = match.provider_realm.id if match.provider_realm

        match.instance.instance_matches.exists?(search_params)
      end

      if @assembly_matches.any?
        @assembly_matches
      else
        @errors << _('No more matches left. All of them are tried already.')
      end
    end

  end

end
