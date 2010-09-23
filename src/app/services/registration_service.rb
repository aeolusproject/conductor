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

      allow_self_service_logins = MetadataObject.lookup("allow_self_service_logins")
      self_service_default_pool = MetadataObject.lookup("self_service_default_pool")
      self_service_default_role = MetadataObject.lookup("self_service_default_role")
      self_service_default_quota = MetadataObject.lookup("self_service_default_quota")

      @user_quota = Quota.new(:maximum_running_instances => self_service_default_quota.maximum_running_instances,
                              :maximum_total_instances => self_service_default_quota.maximum_total_instances)
      @user_quota.save!
      @user.quota = @user_quota
      @user.save!

      Permission.create!({:user => @user, :role => self_service_default_role, :permission_object => self_service_default_pool})

      return true
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
