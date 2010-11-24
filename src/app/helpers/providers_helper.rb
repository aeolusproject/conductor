module ProvidersHelper

  def edit_button(provider, action)
    if provider and ['show', 'accounts'].include? action
      link_to 'Edit', edit_provider_path(provider), :class => 'button'
    else
      content_tag('a', 'Edit', :href => '#', :class => 'button disabled')
    end
  end

end
