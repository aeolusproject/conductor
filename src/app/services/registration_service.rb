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

    User.transaction do
      begin
        if @user.quota.nil? || @user.quota.invalid?
          self_service_default_quota = MetadataObject.lookup("self_service_default_quota")
          @user.quota = Quota.new(
            :maximum_running_instances => self_service_default_quota.maximum_running_instances,
            :maximum_total_instances => self_service_default_quota.maximum_total_instances)
        end

        @user.save!

        self_service_default_role = MetadataObject.lookup("self_service_default_role")
        self_service_default_pool = MetadataObject.lookup("self_service_default_pool")
        Permission.create!(:user => @user, :role => self_service_default_role,
                           :permission_object => self_service_default_pool)
        return true
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n  ")
        @error = e.message
        raise ActiveRecord::Rollback
      end
    end
    return false
  end

  def valid?
    @user.valid?
  end
end
