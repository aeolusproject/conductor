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

module PoolProviderAccountOptionsHelper

  def pool_provider_account_options_header(options = {})
    [
      { :name => _('Account Name'), :sortable => false },
      { :name => _('Username'), :sortable => false },
      { :name => _('Provider Name'), :sortable => false },
      { :name => _('Provider Type'), :sortable => false },
      { :name => _('Quota Used'), :sortable => false, :class => 'center' },
      { :name => _('Quota Limit'), :sortable => false, :class => 'center' },
      { :name => _('Score'), :sortable => false, :class => 'center' },
    ]
  end

  def render_score(options, provider_account)
    provider_account_option = options.find do |option|
      option.provider_account_id == provider_account.id
    end

    if provider_account_option
      link_to(provider_account_option.score, edit_pool_provider_selection_provider_account_option_path(provider_account_option.pool_id, provider_account_option))
    else
      link_to(0, new_pool_provider_selection_provider_account_option_path(:provider_account_id => provider_account.id))
    end

  end

end
