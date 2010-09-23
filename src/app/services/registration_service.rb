class RegistrationService
  attr_reader :error

  def initialize(user)
    @user = user
  end

  def save
    unless valid?
      @error = "validation failed"
      return false
    end

    begin
    User.transaction do
      @user.save!
      @pool = Pool.create!({ :name => @user.login, :zone => Zone.default})

      @quota = Quota.new
      @quota.save!

      @pool.quota_id = @quota.id
      @pool.save!

      raise "Role 'Instance Creator and User' doesn't exist" unless
        role = Role.find_by_name("Instance Creator and User")

      Permission.create!({:user => @user,
                          :role => role,
                          :permission_object => @pool})
    end
    rescue
      Rails.logger.error $!.message
      Rails.logger.error $!.backtrace.join("\n  ")
      @error = $!.message
      false
    end
  end

  def valid?
    @user.valid?
  end
end
