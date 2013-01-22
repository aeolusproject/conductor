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
module ProviderAccountsHelper
  def provider_accounts_header(options = {})
    columns = [{ :name => 'checkbox', :sortable => false, :class => 'checkbox' }]

    unless options[:without_alert]
      columns << { :name => '', :sortable => false, :class => 'alert' }
    end

    columns += [
      { :name => _("Account Name"), :sortable => false },
      { :name => _("Username"), :sortable => false},
      { :name => _("Provider Name"), :sortable => false },
      { :name => _("Provider Type"), :sortable => false },
      { :name => _("Priority"), :sortable => false, :class => 'center' },
      { :name => _("Quota Used"), :sortable => false, :class => 'center' },
      { :name => _("Quota Limit"), :sortable => false, :class => 'center' }
    ]
  end
end
