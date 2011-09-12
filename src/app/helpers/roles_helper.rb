module RolesHelper
  def roles_header
    [
      { :name => '', :sortable => false },
      { :name => t("roles.index.role_name"), :sortable => :name },
    ]
  end
end
