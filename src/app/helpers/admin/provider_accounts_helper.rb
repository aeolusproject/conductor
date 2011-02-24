module Admin::ProviderAccountsHelper

  def display_provider_account_login_form(provider_type)
    unless provider_type.codename.nil?
      render :partial => provider_type.codename
    else
      flash.now[:warning] = "You don't have any provider yet"
    end
  end
end
