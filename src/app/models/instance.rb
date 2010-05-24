#
# Copyright (C) 2009 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Instance < ActiveRecord::Base
  include SearchFilter

  cattr_reader :per_page
  @@per_page = 15

  belongs_to :pool
  belongs_to :cloud_account

  belongs_to :hardware_profile
  belongs_to :image
  belongs_to :realm

  validates_presence_of :pool_id
  validates_presence_of :hardware_profile_id
  validates_presence_of :image_id

  #validates_presence_of :external_key
  # TODO: can we do uniqueness validation on indirect association
  # -- pool.account.provider
  #validates_uniqueness_of :external_key, :scope => :provider_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :pool_id
  validates_length_of :name, :maximum => 1024

  # FIXME: for now, hardware profile is required, realm is optional, although for RHEV-M,
  # hardware profile may be optional too
  validates_presence_of :hardware_profile_id
  validates_presence_of :image_id

  STATE_NEW            = "new"
  STATE_PENDING        = "pending"
  STATE_RUNNING        = "running"
  STATE_SHUTTING_DOWN  = "shutting_down"
  STATE_STOPPED        = "stopped"
  STATE_CREATE_FAILED  = "create_failed"

  validates_inclusion_of :state,
     :in => [STATE_NEW, STATE_PENDING, STATE_RUNNING,
             STATE_SHUTTING_DOWN, STATE_STOPPED, STATE_CREATE_FAILED]

  # used to get sorting column in controller and in view to generate datatable definition and
  # html table structure
  COLUMNS = [
    {:id => 'id', :header => '<input type="checkbox" id="image_id_all" onclick="checkAll(event)">', :opts => {:checkbox_id => 'image_id', :searchable => false, :sortable => false, :width => '1px', :class => 'center'}},
    {:id => 'actions', :header => 'Actions', :opts => {:width => "15%", :sortable => false}},
    {:id => 'name', :header => 'Name', :opts => {:width => "25%"}},
    {:id => 'state', :header => 'State', :opts => {:width => "15%"}},
    {:id => 'hwprofile', :header => 'HW profile', :opts => {:width => "15%"}},
    {:id => 'image', :header => 'Image', :opts => {:sortable => false}},
  ]

  SEARCHABLE_COLUMNS = %w(name state)

  def get_action_list(user=nil)
    # return empty list rather than nil
    # FIXME: not handling pending state now -- only current state
    return_val = InstanceTask.valid_actions_for_instance_state(state,
                                                               self,
                                                               user) || []
    # filter actions based on quota
    # FIXME: not doing quota filtering now
    return_val
  end

  # Provide method to check if requested action exists, so caller can decide
  # if they want to throw an error of some sort before continuing
  # (ie in service api)
  def valid_action?(action)
    return get_action_list.include?(action) ? true : false
  end

  def queue_action(user, action, data = nil)
    return false unless get_action_list.include?(action)
    task = InstanceTask.new({ :user        => user,
                              :task_target => self,
                              :action      => action,
                              :args        => data})
    task.save!
    return task
  end

  def front_end_realm
    unless cloud_account.nil?
      cloud_account.provider.name + Realm::AGGREGATOR_REALM_PROVIDER_DELIMITER +
        cloud_account.username + (realm.nil? ? "" :
                                  (Realm::AGGREGATOR_REALM_ACCOUNT_DELIMITER +
                                   realm.name))
    end
  end

  def front_end_realm=(realm_name)
    provider_name, tmpstr = realm_name.split(Realm::AGGREGATOR_REALM_PROVIDER_DELIMITER,2)
    account_name, realm_name = tmpstr.split(Realm::AGGREGATOR_REALM_ACCOUNT_DELIMITER,2)
    provider = Provider.find_by_name(provider_name)
    self.cloud_account = provider.cloud_accounts.find_by_username(account_name)
    self.realm = provider.realms.find_by_name(realm_name) unless realm_name.nil?
  end

  def total_run_time
    if state == STATE_RUNNING
      acc_run_time + (Time.now - time_last_start)
    else
      acc_run_time
    end
  end

end
