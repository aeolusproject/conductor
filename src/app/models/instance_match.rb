class InstanceMatch < ActiveRecord::Base
  belongs_to :instance
  belongs_to :pool_family
  belongs_to :provider_account
  belongs_to :hardware_profile
  belongs_to :realm

  def equals?(other)
    return self.nil? && other.nil? if (self.nil? || other.nil?)
    self.pool_family_id == other.pool_family_id &&
      self.provider_account_id == other.provider_account_id &&
      self.hardware_profile_id == other.hardware_profile_id &&
      self.provider_image == other.provider_image &&
      self.realm_id == other.realm_id &&
      self.instance_id == other.instance_id
  end
end
