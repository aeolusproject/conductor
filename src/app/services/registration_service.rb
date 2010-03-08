class RegistrationService

  def initialize(user)
    @user = user
  end

  def save
    return false unless valid?
    begin
    User.transaction do
      @user.save!
      @portal_pool = PortalPool.create!({ :name => @user.login, :owner => @user})
      Permission.create!({:user => @user,
                          :role => Role.find_by_name("Self-service Pool User"),
                          :permission_object => @portal_pool})
    end
    rescue
      false
    end
  end

  def valid?
    @user.valid?
  end
end
