module RealmsHelper
  def realms_header
    [
      {:name => '', :class => 'checkbox', :sortable => false},
      {:name => t("realms.index.realm_name"), :sort_attr => :name}
    ]
  end
end
