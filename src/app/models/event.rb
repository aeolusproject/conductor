#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

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
  acts_as_paranoid

  require "#{Rails.root}/lib/aeolus/event.rb"
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
        instance = Instance.unscoped.find(source_id)
        # If we have a time_last_running, use it; otherwise, we just started and it's not populated yet
        start_time = instance.time_last_running || Time.now
        terminate_time = status_code == 'stopped' ? instance.time_last_stopped : nil
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
          logger.error "Caught exception trying to save event for instance: #{e.message}"
          return true
        end
      end
      # There is also a "summary" attribute on state changes, but we don't appear to need to check it
    when "Deployment"
      if ['some_stopped', 'first_running', 'all_stopped', 'all_running'].include?(status_code)
        deployment = Deployment.unscoped.find(source_id)
        begin
          # TODO - The Cddr method supports a :deployable_id, but we don't implement this at the moment
          e = Aeolus::Event::Cddr.new({
            :deployment_id => deployment.id,
            :owner => deployment.owner.login,
            :pool => deployment.pool.name,
            :provider => (deployment.provider.name rescue "-nil-"),
            :provider_type => (deployment.provider.provider_type.name rescue "-nil-"),
            :provider_account => (deployment.instances.first.provider_account.label rescue "-nil-"),
            :start_time => deployment.start_time,
            :terminate_time => deployment.end_time,
            :old_values => old_values,
            :action => status_code
          })
          e.process
        rescue Exception => e
          logger.error "Caught exception trying to save event for deployment: #{e.message}"
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
