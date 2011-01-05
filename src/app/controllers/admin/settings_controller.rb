class Admin::SettingsController < ApplicationController
  before_filter :require_user

  # Settings MetaData Keys
  SELF_SERVICE_DEFAULT_QUOTA = "self_service_default_quota"
  KEYS = [SELF_SERVICE_DEFAULT_QUOTA]

  def self_service
    if !is_admin?
      raise PermissionError.new('You have insufficient privileges to perform action.')
      return
    end
    @self_service_default_quota = MetadataObject.lookup(SELF_SERVICE_DEFAULT_QUOTA)
  end

  def general_settings
    if !is_admin?
      raise PermissionError.new('You have insufficient privileges to perform action.')
      return
    end
  end

  def update
    KEYS.each do |key|
      if params[key]
        if key == SELF_SERVICE_DEFAULT_QUOTA
          @self_service_default_quota = MetadataObject.lookup(key)
          if !@self_service_default_quota.update_attributes(params[key])
            flash[:notice] = "Could not update the default quota"
            render :self_service
            return
          end
        elsif key == SELF_SERVICE_DEFAULT_POOL
          if Pool.exists?(params[key])
            MetadataObject.set(key, Pool.find(params[key]))
          end
        elsif key == SELF_SERVICE_DEFAULT_ROLE
          if Role.exists?(params[key])
            MetadataObject.set(key, Role.find(params[key]))
          end
        else
          MetadataObject.set(key, params[key])
        end
      end
    end
    flash[:notice] = "Settings Updated!"
    redirect_to :action => 'self_service'
  end

  private
  def is_admin?
    is_admin = @current_user.permissions.collect { |p| p.role }.find { |r| r.name == "Administrator" }
    return is_admin == nil ? false : true
  end
end
