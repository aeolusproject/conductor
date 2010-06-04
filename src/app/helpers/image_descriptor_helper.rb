module ImageDescriptorHelper
  def tree_list(domid, data, action_name, action_callback)
    list = data.map do |group, pkgs|
      package_list(pkgs, action_name, action_callback)
    end
    return "<ul id='#{domid}' class='filetree'><li>" + list.join("</li><li>") + "</li></ul>"
  end

  def package_list(pkgs, action_name, action_callback)
    list = pkgs.map do |pkg|
      "<span class='pkgname'>#{pkg[:name]}</span><span style='float:right' onclick='#{action_callback}'>#{action_name}</span>"
    end
    return "<li>" + list.join("</li><li>") + "</li>"
  end

  def js_add_group_cmd(group, pkgs)
    "select_group({group: '#{group}', pkgs: ['#{pkgs.map {|p| p[:name]}.join("','")}']});"
  end

  def select_repository_tag(repositories)
    select_tag("repository", ["<option value='all' selected='selected'>All</option>"] + repositories.map{|repid, rep| "<option value=\"#{repid}\">#{rep['name']}</option>"}, {:onchange => "get_repository(event)"})
  end

  def image_target_actions(target)
    str = ''
    if ImageDescriptorTarget::ACTIVE_STATES.include?(target.status)
      str = link_to 'Cancel', {:controller => 'image_descriptor_target', :action => 'cancel', :id => target.id}
    end
    return str
  end
end
