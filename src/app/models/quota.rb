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
# Schema version: 20110207110131
#
# Table name: quotas
#
#  id                        :integer         not null, primary key
#  running_instances         :integer         default(0)
#  total_instances           :integer         default(0)
#  maximum_running_instances :integer
#  maximum_total_instances   :integer
#  lock_version              :integer         default(0)
#  created_at                :datetime
#  updated_at                :datetime
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class Quota < ActiveRecord::Base

  self.table_name = "quotas"

  has_one :pool
  has_one :pool_family
  has_one :provider_account
  has_one :user

  validates_numericality_of :maximum_total_instances,
                            :greater_than_or_equal_to => 0,
                            :less_than_or_equal_to => 2147483647,
                            :only_integer => true,
                            :allow_nil => true,
                            :message => _("must be a positive whole number less than 2147483647")

  validates_numericality_of :maximum_running_instances,
                            :greater_than_or_equal_to => 0,
                            :less_than_or_equal_to => 2147483647,
                            :only_integer => true,
                            :allow_nil => true,
                            :message => _("must be a positive whole number less than 2147483647")

  QuotaResource = Struct.new(:name, :used, :max, :available, :unit)

  NO_LIMIT = nil

  RESOURCE_RUNNING_INSTANCES = "running_instances"
  RESOURCE_TOTAL_INSTANCES = "total_instances"
  RESOURCE_OVERALL = "overall"

  RESOURCE_NAMES = [ RESOURCE_RUNNING_INSTANCES, RESOURCE_TOTAL_INSTANCES ]

  def set_maximum_running_instances(value)
    if value.blank? || value == _("unlimited")
      self.maximum_running_instances = Quota::NO_LIMIT
    else
      self.maximum_running_instances = value
    end
  end


  def self.can_create_instance?(instance, cloud_account)
    [instance.owner, instance.pool, cloud_account].each do |parent|
      if parent
        quota = Quota.find(parent.quota_id)
        if !quota.can_create? instance
          return false
        end
      end
    end
    return true
  end

  def self.can_start_instance?(instance, cloud_account)
    [instance.owner, instance.pool, cloud_account].each do |parent|
      if parent
        quota = Quota.find(parent.quota_id)
        if !quota.can_start? instance
          return false
        end
      end
    end
    return true
  end

  def can_start?(instances)
    size = (instances.kind_of? Array) ? instances.size : 1
    potential_running_instances = running_instances + size
    if !Quota.no_limit(maximum_running_instances) && maximum_running_instances < potential_running_instances
      return false
    end
    return true
  end

  def can_create?(instances)
    size = (instances.kind_of? Array) ? instances.size : 1
    potential_total_instances = total_instances + size
    if !Quota.no_limit(maximum_total_instances) && maximum_total_instances < potential_total_instances
      return false
    end
    return true
  end

  def reached?
    !Quota.no_limit(maximum_running_instances) && running_instances >= maximum_running_instances
  end

  def quota_resources()
    quota_resources =  {"running_instances" => QuotaResource.new("Running Instances", running_instances, maximum_running_instances, nil, ""),
            "total_instances" => QuotaResource.new("Total Instances", total_instances, maximum_total_instances, nil, "")}

    quota_resources.each_value do |quota_resource|
      if Quota.no_limit(quota_resource.max)
        quota_resource.max = "No Limit"
        quota_resource.available = "N\A"
      else
        quota_resource.available = quota_resource.max - quota_resource.used
        if quota_resource.available < 0
          quota_resource.available = quota_resource.available * -1
          quota_resource.available = "OverLimit By: " + quota_resource.available.to_s
        end
      end
    end

    return quota_resources
  end

  def percentage_used(count=running_instances)
    if Quota.no_limit(maximum_running_instances) || count == 0
      return 0
    elsif maximum_running_instances == 0
      return 100
    else
      percentage_used = (count.to_f / maximum_running_instances.to_f) * 100
      return percentage_used
    end
  end

  def self.no_limit(resource)
    if resource.to_s == NO_LIMIT.to_s
      return true
    end
    return false
  end

  def self.new_for_user
    self.new(:maximum_running_instances =>
             MetadataObject.lookup("self_service_default_quota").
             maximum_running_instances)
  end
end
