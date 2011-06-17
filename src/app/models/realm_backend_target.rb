# == Schema Information
# Schema version: 20110207110131
#
# Table name: realm_backend_targets
#
#  id                     :integer         not null, primary key
#  realm_or_provider_id   :integer         not null
#  realm_or_provider_type :string(255)     not null
#  frontend_realm_id      :integer         not null
#

class RealmBackendTarget < ActiveRecord::Base
  belongs_to :frontend_realm
  belongs_to :realm_or_provider, :polymorphic =>true
  belongs_to :realm,  :class_name => 'Realm', :foreign_key => 'realm_or_provider_id'
  belongs_to :provider,  :class_name => 'Provider', :foreign_key => 'realm_or_provider_id'

  validates_uniqueness_of :frontend_realm_id, :scope => [:realm_or_provider_id, :realm_or_provider_type]

  def target_realm
    (realm_or_provider_type == "Realm") ? realm : nil
  end

  def target_provider
    (realm_or_provider_type == "Realm") ? realm.provider : provider
  end
end
