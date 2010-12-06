module ProvidersHelper

  def edit_button(provider, action)
    if provider and action == 'show'
      link_to 'Edit', edit_provider_path(provider), :class => 'button', :id => 'edit_button'
    else
      content_tag('a', 'Edit', :href => '#', :class => 'button disabled')
    end
  end

end
