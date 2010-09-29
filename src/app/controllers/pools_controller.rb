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

require 'util/condormatic'

class PoolsController < ApplicationController
  before_filter :require_user, :get_nav_items

  def section_id
    'administration'
  end

  def index
    @header = [
      { :name => "Pool name", :sort_attr => :name },
      { :name => "% Quota used", :sortable => false },
      { :name => "Quota (Instances)", :sort_attr => "quotas.total_instances"},
      { :name => "Zone", :sort_attr => "zones.name" }
    ]
    @pools = Pool.paginate(:all, :include => [ :quota, :zone ],
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end


  def show
    @pool = Pool.find(params[:id])
  end

  def edit
    @pool = Pool.find(params[:id])
  end

  def list
    #FIXME: clean this up, many error cases here
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::INSTANCE_VIEW,@pool)
    @pool.reload

    @order_dir = params[:order_dir] == 'desc' ? 'desc' : 'asc'
    @order = params[:order] || 'name'

    @instances = Instance.search_filter(params[:search], Instance::SEARCHABLE_COLUMNS).paginate(
      :page => params[:page] || 1,
      :order => @order + ' ' + @order_dir,
      :conditions => {:pool_id => @pool.id}
    )

    if request.xhr? and params[:partial]
      render :partial => 'instance/instances'
      return
    end
  end

  def hardware_profiles
    @pool = Pool.find(params[:id])
    @hardware_profiles = @pool.hardware_profiles
    require_privilege(Privilege::POOL_VIEW, @pool)
  end

  def realms
    @pool = Pool.find(params[:id])
    @realm_names = @pool.realms
    require_privilege(Privilege::POOL_VIEW,@pool)
  end

  def new
    require_privilege(Privilege::POOL_MODIFY)
    @pools = Pool.list_for_user(@current_user, Privilege::POOL_MODIFY)
    @pool = Pool.new
  end

  def create
    require_privilege(Privilege::POOL_MODIFY)

    #FIXME: This should probably be in a transaction
    @pool = Pool.new(params[:pool])
    # FIXME: do we need any more handling around save failures? What if perm
    #        creation fails?

    quota = Quota.new
    quota.save!

    @pool.quota_id = quota.id

    @pool.zone = Zone.default
    @pool.save!

    flash[:notice] = "Pool added."
    redirect_to :action => 'show', :id => @pool.id
  end

  def delete
  end

  def accounts_for_pool
    @pool =  Pool.find(params[:pool_id])
    require_privilege(Privilege::ACCOUNT_VIEW,@pool)
    @cloud_accounts = []
    all_accounts = CloudAccount.list_for_user(@current_user, Privilege::ACCOUNT_ADD)
    all_accounts.each {|account|
      @cloud_accounts << account unless @pool.cloud_accounts.map{|x| x.id}.include?(account.id)
    }
  end

  def add_account
    @pool = Pool.find(params[:pool])
    @cloud_account = CloudAccount.find(params[:cloud_account])
    require_privilege(Privilege::ACCOUNT_ADD,@pool)
    require_privilege(Privilege::ACCOUNT_ADD,@cloud_account)
    Pool.transaction do
      @pool.cloud_accounts << @cloud_account unless @pool.cloud_accounts.map{|x| x.id}.include?(@cloud_account.id)
      @pool.save!
      @pool.populate_realms_and_images([@cloud_account])
    end
    redirect_to :action => 'show', :id => @pool.id
  end
  condormatic_classads_sync
end
