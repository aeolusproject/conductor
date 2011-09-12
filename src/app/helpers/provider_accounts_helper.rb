module ProviderAccountsHelper
  def provider_accounts_header
    [
      { :name => '', :sortable => false },
      { :name => t("provider_accounts.index.provider_account_name"), :sortable => false },
      { :name => t("provider_accounts.index.username"), :sortable => false},
      { :name => t("provider_accounts.index.provider_name"), :sortable => false },
      { :name => t("provider_accounts.index.provider_type"), :sortable => false },
      { :name => t("provider_accounts.index.quota_used"), :sortable => false },
      { :name => t("provider_accounts.index.quota_limit"), :sortable => false }
    ]
  end
end
