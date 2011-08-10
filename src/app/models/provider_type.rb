# == Schema Information
# Schema version: 20110309105149
#
# Table name: provider_types
#
#  id              :integer         not null, primary key
#  name            :string(255)     not null
#  codename        :string(255)     not null
#  ssh_user        :string(255)
#  home_dir        :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#

class ProviderType < ActiveRecord::Base

  has_many :providers
  has_many :credential_definitions, :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :deltacloud_driver
  validates_uniqueness_of :deltacloud_driver

end
