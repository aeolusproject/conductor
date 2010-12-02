Before do
  @default_zone_metadata = Factory.create(:default_zone_metadata)
  @allow_self_service_logins = Factory(:metadata_object, :key => "allow_self_service_logins", :value => "true")

  @default_quota = Factory(:unlimited_quota)
  @self_service_default_quota = Factory(:metadata_object, :key => "self_service_default_quota",
                                                          :value => @default_quota,
                                                          :object_type => "Quota")

  @default_pool = Factory(:pool, :name => "default_pool", :quota => @default_quota)
  @self_service_default_pool = Factory(:metadata_object, :key => "self_service_default_pool",
                                                        :value => @default_pool,
                                                        :object_type => "Pool")

  @default_role = Role.find(:first, :conditions => ['name = ?', 'Instance Creator and User'])
  @self_service_default_pool = Factory(:metadata_object, :key => "self_service_default_role",
                                                        :value => @default_role,
                                                        :object_type => "Role")
end
