SimpleNavigation::Configuration.run do |navigation|
  navigation.autogenerate_item_ids = false
  navigation.items do |first_level|
    first_level.item :resource_management_view, t(:resource_management_view), '#' do |second_level|
      second_level.item :pools, t(:pools), '#'
      second_level.item :deployments, t(:deployments),'#'
      second_level.item :instances, t(:instances), '#'
      second_level.item :searches, t(:searches), '#'
    end
    first_level.item :image_factory_view, t(:image_factory_view), '#' do |second_level|
      second_level.item :templates, t(:templates), '#'
      second_level.item :assemblies, t(:assemblies),'#'
      second_level.item :deployables, t(:deployables), '#'
      second_level.item :template_collections, t(:template_collections), '#'
    end
    first_level.item :administration, t(:admin), '#' do |second_level|
      second_level.item :users, t(:users), '#'
      second_level.item :roles, t(:roles), '#'
      second_level.item :cloud_providers, t(:cloud_providers), '#'
      second_level.item :provider_account, t(:provider_account), '#'
      second_level.item :cloud_engine_hardware_profiles, t(:cloud_engine_hardware_profiles), '#'
      second_level.item :cloud_engine_realms, t(:cloud_engine_realms), '#'
      second_level.item :pool_families, t(:pool_families), '#'
      second_level.item :settings, t(:setting), '#'
    end
    first_level.item :dashboard, t(:dashboard), '#'
  end
end
