# == Schema Information
# Schema version: 20110616100915
#
# Table name: deployments
#
#  id                :integer         not null, primary key
#  name              :string(1024)    not null
#  realm_id          :integer
#  owner_id          :integer
#  pool_id           :integer         not null
#  lock_version      :integer         default(0)
#  created_at        :datetime
#  updated_at        :datetime
#  frontend_realm_id :integer
#  deployable_xml    :text
#

#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

require 'sunspot_rails'
require 'util/deployable_xml'

class Deployment < ActiveRecord::Base
  include SearchFilter
  include PermissionedObject

  searchable do
    text :name, :as => :code_substring
  end

  belongs_to :pool

  has_many :instances

  belongs_to :realm
  belongs_to :frontend_realm

  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  belongs_to :owner, :class_name => "User", :foreign_key => "owner_id"
  after_create "assign_owner_roles(owner)"
  # TODO - Strictly, this should be a belongs_to, but :through seems to only work one-way,
  # and we don't much care about the inverse here.
  has_one :provider, :through => :realm

  validates_presence_of :pool_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :pool_id
  validates_length_of :name, :maximum => 1024
  validates_presence_of :owner_id

  before_destroy :destroyable?

  SEARCHABLE_COLUMNS = %w(name)

  USER_MUTABLE_ATTRS = ['name']

  def validate
    begin
      deployable_xml.validate!
    rescue DeployableXML::ValidationError => e
      errors.add(:deployable_xml, e.message)
    end
  end

  def object_list
    super << pool
  end
  class << self
    alias orig_list_for_user_include list_for_user_include
    alias orig_list_for_user_conditions list_for_user_conditions
  end

  def self.list_for_user_include
    includes = orig_list_for_user_include
    includes << { :pool => {:permissions => {:role => :privileges}}}
    includes
  end

  def self.list_for_user_conditions
    "(#{orig_list_for_user_conditions}) or
     (permissions_pools.user_id=:user and
      privileges_roles.target_type=:target_type and
      privileges_roles.action=:action)"
  end

  def get_action_list(user=nil)
    # FIXME: how do actions and states interact for deployments?
    # For instances the list comes from the provider based on current state.
    # Deployments don't currently have an explicit state field, but
    # something could be calculated from associated instances.
    ["start", "stop", "reboot"]
  end

  def valid_action?(action)
    return get_action_list.include?(action) ? true : false
  end

  def destroyable?
    instances.all? {|i| i.destroyable? }
  end

  def launch(hw_profiles, user)
    status = { :errors => {}, :successes => {} }
    deployable_xml.assemblies.each do |assembly|
      # TODO: for now we try to start all instances even if some of them fails
      begin
        Instance.transaction do
          hw_profile = HardwareProfile.frontend.find_by_name(assembly.hwp)
          raise "Hardware Profile #{assembly.hwp} not found." unless hw_profile
          instance = Instance.create!(
            :deployment => self,
            :name => "#{name}/#{assembly.name}",
            :frontend_realm => frontend_realm,
            :pool => pool,
            :image_uuid => assembly.image_id,
            :image_build_uuid => assembly.image_build,
            :assembly_xml => assembly.to_s,
            :state => Instance::STATE_NEW,
            :owner => user,
            :hardware_profile => hw_profile
          )
          task = InstanceTask.create!({:user        => user,
                                       :task_target => instance,
                                       :action      => InstanceTask::ACTION_CREATE})
          condormatic_instance_create(task)
        end
        status[:successes][assembly.name] = 'launched'
      rescue
        logger.error $!
        logger.error $!.backtrace.join("\n    ")
        status[:errors][assembly.name] = $!
      end
    end
    status
  end

  def self.list_or_search(query,order_field,order_dir)
    if query.blank?
      deployments = Deployment.all(:include => :owner,
                                   :order => (order_field || 'name') +' '+ (order_dir || 'asc'))
    else
      deployments = search() { keywords(query) }.results
    end
    deployments
  end

  def deployable_xml
    @deployable_xml ||= DeployableXML.new(self[:deployable_xml].to_s)
  end

  def import_xml_from_url(url)
    # Right now we allow this to raise exceptions on timeout / errors
    resource = RestClient::Resource.new(url, :open_timeout => 10, :timeout => 45)
    response = resource.get
    if response.code == 200
      self.deployable_xml = response
    else
      false
    end
  end

end
