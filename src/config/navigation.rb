SimpleNavigation::Configuration.run do |navigation|
  navigation.autogenerate_item_ids = false
  navigation.items do |first_level|
    first_level.item :resource_management, t(:resource_management), pools_path, :highlights_on => /^\/$/ do |second_level|
      second_level.item :pools, t('pools.index.pools'), pools_path
      second_level.item :deployments, t('deployments.deployments'),deployments_path, :highlights_on => /^\/$|\/deployments/
      second_level.item :instances, t("instances.instances"), instances_path
    end
    first_level.item :image_factory, t(:image_factory), templates_path, :highlights_on => /\/image_factory/ do |second_level|
      second_level.item :templates, t('templates.templates'), templates_path
      second_level.item :assemblies, t(:assemblies), assemblies_path
      second_level.item :deployables, t('deployables.index.deployables'), deployables_path
      second_level.item :image_imports, t(:image_imports), new_image_import_path
    end
    first_level.item :administration, t(:administration), users_path, :highlights_on => /\/admin/ do |second_level|
      second_level.item :users, t(:users), users_path
      second_level.item :roles, t(:roles), roles_path
      second_level.item :providers, t('providers.providers'), providers_path
      second_level.item :provider_accounts, t(:provider_accounts_item), provider_accounts_path
      second_level.item :hardware_profiles, t(:cloud_engine_hardware_profiles), hardware_profiles_path
      second_level.item :realms, t(:cloud_engine_realms), realms_path
      second_level.item :pool_families, t('pool_families.pool_families'), pool_families_path
      second_level.item :settings, t('settings.settings'), settings_path
    end
    first_level.item :dashboard, t(:dashboard), '#'
  end
end
