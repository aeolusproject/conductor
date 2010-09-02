SimpleNavigation::Configuration.run do |navigation|
  navigation.items do |primary|
    primary.dom_class = 'nav'
    primary.item :dashboard, t(:dashboard), :controller => "dashboard"
    primary.item :instances, t(:instances), :controller => "instance"
    primary.item :templates, t(:templates), :controller => "image", :action => "show"
    primary.item :users, t(:users), {:controller => "permissions", :action => "list"} , :if => lambda {
      @current_user && has_view_perms?(BasePermissionObject.general_permission_scope) }
    primary.item :settings, t(:settings), :controller => "settings"
  end
end
