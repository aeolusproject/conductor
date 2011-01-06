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
      { :name => "Pool Family", :sort_attr => "pool_families.name" }
    ]
    @pools = Pool.paginate(:all, :include => [ :quota, :pool_family ],
      :page => params[:page] || 1,
      :order => (params[:order_field] || 'name') +' '+ (params[:order_dir] || 'asc')
    )
  end


  def show
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::VIEW, @pool)
  end

  def edit
    @pool = Pool.find(params[:id])
    require_privilege(Privilege::MODIFY, @pool)
  end

  def list
    #FIXME: clean this up, many error cases here
    @pool = Pool.find(params[:id])
    # FIXME: really we need perm-filtered list here
    require_privilege(Privilege::VIEW, @pool)
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
    require_privilege(Privilege::VIEW, @pool)
  end

  def realms
    @pool = Pool.find(params[:id])
    @realm_names = @pool.realms
    require_privilege(Privilege::VIEW, @pool)
  end

  def new
    require_privilege(Privilege::CREATE, Pool)
    @pools = Pool.list_for_user(@current_user, Privilege::MODIFY)
    @pool = Pool.new
  end

  def create
    require_privilege(Privilege::CREATE, Pool)

    #FIXME: This should probably be in a transaction
    @pool = Pool.new(params[:pool])
    # FIXME: do we need any more handling around save failures? What if perm
    #        creation fails?

    quota = Quota.new
    quota.save!

    @pool.quota_id = quota.id

    @pool.pool_family = PoolFamily.default
    if @pool.save
      flash[:notice] = "Pool added."
      redirect_to :action => 'show', :id => @pool.id
    else
      render :action => :new
    end
  end

  def manage_pool
    type = params[:commit]
    pool_id = params[:pool_checkbox]
    if type && Pool.exists?(pool_id)
      if type == "edit"
        redirect_to :action => 'edit', :id => pool_id
      elsif type == "delete"
        require_privilege(Privilege::MODIFY, Pool.find(pool_id))
        params[:id] = pool_id
        destroy
      end
    else
      flash[:notice] = "Error performing this operation"
      redirect_to pool_path
    end
  end

  def delete
  end

  kick_condor
end
