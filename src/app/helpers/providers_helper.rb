#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module ProvidersHelper

  def edit_button(provider, action)
    if provider and action == 'show'
      link_to 'Edit', edit_provider_path(provider), :class => 'button', :id => 'edit_button'
    else
      content_tag('a', 'Edit', :href => '#', :class => 'button disabled')
    end
  end

end
