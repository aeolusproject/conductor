module RealmsHelper
  def realms_header
    [
      {:name => '', :sortable => false},
      {:name => t("realms.index.realm_name"), :sort_attr => :name}
    ]
  end
end
