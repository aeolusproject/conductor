# == Schema Information
# Schema version: 20110309105149
#
# Table name: credential_definitions
#
#  id               :integer         not null, primary key
#  name             :string(255)
#  label            :string(255)
#  input_type       :string(255)
#  provider_type_id :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class CredentialDefinition < ActiveRecord::Base
  belongs_to :provider_type
  has_many :credentials
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :provider_type_id
  validates_presence_of :label
  validates_presence_of :input_type
  validates_presence_of :provider_type_id
  CREDENTIAL_DEFINITIONS_ORDER = ["username", "password", "account_id", "x509private", "x509public"]
end
