Alberich.user_class = "User"
Alberich.groups_for_user_method = "all_groups"
Alberich.user_group_class = "UserGroup"
Alberich.permissioned_object_classes = ["HardwareProfile", "Catalog",
                                        "Deployable", "PoolFamily", "Pool",
                                        "Deployment", "Instance", "Provider",
                                        "ProviderAccount", "ProviderType",
                                        "Tim::BaseImage", "Tim::Template"]
Alberich.additional_privilege_scopes = ["FrontendRealm", "User", "Quota"]

Alberich.require_user_method = "require_user"

ActiveSupport.on_load(:action_controller) do
  ActionController::Base.send(:include, Alberich::ApplicationControllerHelper)
end
