class RegistrationService
  attr_reader :error

  def initialize(user)
    @user = user
  end

  def save
    User.transaction do
      begin
        if @user.quota.nil?
          self_service_default_quota = MetadataObject.lookup("self_service_default_quota")
          @user.quota = Quota.new(
            :maximum_running_instances => self_service_default_quota.maximum_running_instances,
            :maximum_total_instances => self_service_default_quota.maximum_total_instances)
        end

        @user.save!
        # perm list in the format:
        #   "[resource1_key, resource1_role], [resource2_key, resource2_role], ..."
        MetadataObject.lookup("self_service_perms_list").split(/[\]],? ?|[\[]/).
          select {|x| !x.empty? }.each do |x|
            obj_key, role_key = x.split(/, ?/)
            default_obj = MetadataObject.lookup(obj_key)
            default_role = MetadataObject.lookup(role_key)
            Permission.create!(:user => @user, :role => default_role, :permission_object => default_obj)
          end
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
