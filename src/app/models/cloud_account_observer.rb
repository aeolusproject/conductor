class CloudAccountObserver < ActiveRecord::Observer
  def after_create(account)
    if key = account.generate_auth_key
      account.update_attribute(:instance_key, InstanceKey.create!(:pem => key.pem, :name => key.id, :instance_key_owner => account))
    end
  end
end

CloudAccountObserver.instance
