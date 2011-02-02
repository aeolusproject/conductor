module Admin::ProviderAccountsHelper

  def display_provider_account_login_form(provider_type)
    case provider_type
    when 0
      render :partial => "mock"
    when 1
      render :partial => "aws"
    when 2
      render :partial => "gogrid"
    when 3
      render :partial => "rackspace"
    when 4
      render :partial => "rhevm"
    when 5
      render :partial => "opennebula"
    else
      flash.now[:warning] = "You don't have any provider yet"
    end
  end
end
