class RegistrationService

  def initialize(user)
    @user = user
  end

  def save
    return false unless valid?
    begin
    User.transaction do
      @user.save!
      @pool = Pool.create!({ :name => @user.login, :owner => @user})

      @quota = Quota.new
      @quota.save!

      @pool.quota_id = @quota.id
      @pool.save!

      Permission.create!({:user => @user,
                          :role => Role.find_by_name("Instance Creator and User"),
                          :permission_object => @pool})
    end
    rescue
      false
    end
  end

  def valid?
    @user.valid?
  end
end
