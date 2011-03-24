# == Schema Information
# Schema version: 20110309105149
#
# Table name: credentials
#
#  id                       :integer         not null, primary key
#  provider_account_id      :integer
#  value                    :text
#  credential_definition_id :integer         not null
#  created_at               :datetime
#  updated_at               :datetime
#

class Credential < ActiveRecord::Base

  belongs_to :provider_account
  belongs_to :credential_definition
  validates_presence_of :credential_definition_id
  validates_presence_of :value
  validates_uniqueness_of :credential_definition_id, :scope => :provider_account_id
end
