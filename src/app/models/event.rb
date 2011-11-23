#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

# == Schema Information
# Schema version: 20110603204130
#
# Table name: events
#
#  id          :integer         not null, primary key
#  source_id   :integer         not null
#  source_type :string(255)     not null
#  event_time  :datetime
#  status_code :string(255)
#  summary     :string(255)
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Event < ActiveRecord::Base
  require File.join(RAILS_ROOT, 'lib/aeolus/event')
  belongs_to :source, :polymorphic => true

  validates_presence_of :source_id
  validates_presence_of :source_type

  after_create :transmit_event
  attr_accessor :change_hash # allows us to pass in .changes on the parent ("source") object

  scope :lifetime, where(:status_code => [:first_running, :all_running, :some_running, :all_stopped])

  # Notifies the Event API if certain conditions are met
  def transmit_event
    # Extract just the old values from change_hash
    old_values = {}
    change_hash.each_pair do |k,v|
      old_values[k] = v[0]
    end
    case source_type
    when "Instance"
      if ['running', 'stopped'].include?(status_code)
        # If we look this up through the 'source' association, we end up with it being a stale object.
        instance = Instance.find(source_id)
        # If we have a time_last_running, use it; otherwise, we just started and it's not populated yet
        start_time = instance.time_last_running || Time.now
        # If we're stopping, set terminate_time to current time
        terminate_time = status_code == 'stopped' ? Time.now : nil
        # Because this is an after-save hook, rescue any possible exceptions -- if for some reason
        # we cannot save the Event, we don't want to abort the Instance update transaction.
        begin
          e = Aeolus::Event::Cidr.new({
            :instance_id => instance.id,
            :deployment_id => instance.deployment_id,
            :image_uuid => instance.image_uuid,
            :owner => instance.owner.login,
            :pool => instance.pool.name,
            :provider => instance.provider_account.provider.name,
            :provider_type => instance.provider_account.provider.provider_type.name,
            :provider_account => instance.provider_account.label,
            :hardware_profile => instance.hardware_profile.name,
            :start_time => start_time,
            :terminate_time => terminate_time,
            :old_values => old_values,
            :action => status_code
          })
          e.process
        rescue Exception => e
          logger.debug "Caught exception trying to save event for instance: #{e.message}"
          return true
        end
      end
      # There is also a "summary" attribute on state changes, but we don't appear to need to check it
    when "Deployment"
      if ['first_running', 'all_stopped', 'all_running'].include?(status_code)
        deployment = Deployment.find(source_id)
        begin
          # TODO - The Cddr method supports a :deployable_id, but we don't implement this at the moment
          e = Aeolus::Event::Cddr.new({
            :deployment_id => deployment.id,
            :owner => deployment.owner.login,
            :pool => deployment.pool.name,
            :provider => deployment.provider.name,
            :provider_type => deployment.provider.provider_type.name,
            :provider_account => deployment.instances.first.provider_account.label,
            :start_time => deployment.start_time,
            :terminate_time => deployment.end_time,
            :old_values => old_values,
            :action => status_code
          })
          e.process
        rescue Exception => e
          logger.debug "Caught exception trying to svae event for deployment: #{e.message}"
          return true
        end
      end
    end
  end

  # Always return a hash, even if undefined
  def change_hash
    @change_hash || {}
  end
end
