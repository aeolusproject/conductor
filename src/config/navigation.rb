SimpleNavigation::Configuration.run do |navigation|
  navigation.autogenerate_item_ids = false
  navigation.items do |first_level|
    first_level.item :resource_management, t(:resource_management), resources_pools_path, :highlights_on => /^\/$/ do |second_level|
      second_level.item :pools, t(:pools), resources_pools_path
      second_level.item :deployments, t(:deployments),resources_deployments_path, :highlights_on => /^\/$|\/deployments/
      second_level.item :instances, t(:instances), resources_instances_path
    end
    first_level.item :image_factory, t(:image_factory), image_factory_templates_path, :highlights_on => /\/image_factory/ do |second_level|
      second_level.item :templates, t(:templates), image_factory_templates_path
      second_level.item :assemblies, t(:assemblies), image_factory_assemblies_path
      second_level.item :deployables, t(:deployables), image_factory_deployables_path
    end
    first_level.item :administration, t(:administration), admin_users_path, :highlights_on => /\/admin/ do |second_level|
      second_level.item :users, t(:users), admin_users_path
      second_level.item :roles, t(:roles), admin_roles_path
      second_level.item :providers, t('providers.providers'), admin_providers_path
      second_level.item :provider_accounts, t(:provider_accounts_item), admin_provider_accounts_path
      second_level.item :hardware_profiles, t(:cloud_engine_hardware_profiles), admin_hardware_profiles_path
      second_level.item :realms, t(:cloud_engine_realms), admin_realms_path
      second_level.item :pool_families, t(:pool_families), admin_pool_families_path
      second_level.item :settings, t(:setting), admin_settings_path
    end
    first_level.item :dashboard, t(:dashboard), '#'
  end
end
