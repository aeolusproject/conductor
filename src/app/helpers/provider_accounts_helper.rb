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
  def provider_accounts_header
    [
      { :name => 'checkbox', :sortable => false, :class => 'checkbox' },
      { :name => '', :sortable => false, :class => 'alert' },
      { :name => t("provider_accounts.index.provider_account_name"), :sortable => false },
      { :name => t("provider_accounts.index.username"), :sortable => false},
      { :name => t("provider_accounts.index.provider_name"), :sortable => false },
      { :name => t("provider_accounts.index.provider_type"), :sortable => false },
      { :name => t("provider_accounts.index.priority"), :sortable => false, :class => 'center' },
      { :name => t("quota_used"), :sortable => false, :class => 'center' },
      { :name => t("provider_accounts.index.quota_limit"), :sortable => false, :class => 'center' }
    ]
  end

  def no_alerts_provider_accounts_header
    [
      { :name => 'checkbox', :sortable => false, :class => 'checkbox' },
      { :name => t("provider_accounts.index.provider_account_name"), :sortable => false },
      { :name => t("provider_accounts.index.username"), :sortable => false},
      { :name => t("provider_accounts.index.provider_name"), :sortable => false },
      { :name => t("provider_accounts.index.provider_type"), :sortable => false },
      { :name => t("provider_accounts.index.priority"), :sortable => false, :class => 'center' },
      { :name => t("quota_used"), :sortable => false, :class => 'center' },
      { :name => t("provider_accounts.index.quota_limit"), :sortable => false, :class => 'center' }
    ]
  end
end
