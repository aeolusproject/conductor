module ProviderAccountsHelper
  def provider_accounts_header
    [
      { :name => '', :sortable => false, :class => 'checkbox' },
      { :name => '', :sortable => false, :class => 'alert' },
      { :name => t("provider_accounts.index.provider_account_name"), :sortable => false },
      { :name => t("provider_accounts.index.username"), :sortable => false},
      { :name => t("provider_accounts.index.provider_name"), :sortable => false },
      { :name => t("provider_accounts.index.provider_type"), :sortable => false },
      { :name => t("provider_accounts.index.quota_used"), :sortable => false, :class => 'center' },
      { :name => t("provider_accounts.index.quota_limit"), :sortable => false, :class => 'center' }
    ]
  end
end
