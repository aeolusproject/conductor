# == Schema Information
# Schema version: 20110504124706
#
# Table name: view_states
#
#  id         :integer         not null, primary key
#  user_id    :integer
#  name       :string(255)     not null
#  controller :string(255)     not null
#  action     :string(255)     not null
#  state      :text
#  created_at :datetime
#  updated_at :datetime
#

class ViewState < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :user_id
  validates_presence_of :controller
  validates_presence_of :action
  validates_presence_of :state

  # Things that make sense to remember for the session ViewState but not for
  # the saved state -- such as position in the pagination.
  SESSION_ONLY_KEYS = ['page']

  def state
    unless read_attribute(:state).blank?
      JSON.load(read_attribute :state)
    end
  end

  def state=(attrs)
    attrs = attrs || {}
    persistent_attributes = attrs.reject { |k,v| SESSION_ONLY_KEYS.include? k }
    write_attribute :state, JSON.dump(persistent_attributes)
  end
end
