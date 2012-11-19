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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.


class QuotasController < ApplicationController
  before_filter :require_user

  def show
    @parent = get_parent_object(params)
    @parent_type = params[:parent_type]
    @quota = @parent.quota

    require_privilege(Privilege::VIEW, Quota, @parent)
  end

  def edit
    @parent = get_parent_object(params)
    @parent_type = params[:parent_type]
    @name = get_parent_name(@parent, @parent_type)

    @quota = @parent.quota

    require_privilege(Privilege::MODIFY, Quota, @parent)
  end

  def update
    @parent = @parent = get_parent_object(params)
    @parent_type = params[:parent_type]
    require_privilege(Privilege::MODIFY, Quota, @parent)

    @quota = @parent.quota
    @name = get_parent_name(@parent, @parent_type)
    if @quota.update_attributes(params[:quota])
      flash[:notice] = _("Quota updated")
      redirect_to :action => 'show', :id => @parent, :parent_type => @parent_type
    else
      flash[:warning] = _("Could not update quota. Please check you have entered valid values")
      render :action => "edit"
    end
  end

  def reset
    @parent = @parent = get_parent_object(params)
    @parent_type = params[:parent_type]
    require_privilege(Privilege::MODIFY, Quota, @parent)

    @quota = @parent.quota
    @quota.maximum_running_instances = Quota::NO_LIMIT
    @quota.maximum_total_instances = Quota::NO_LIMIT

    if @quota.save!
      flash[:notice] = _("Quota updated")
    end
      redirect_to :action => 'show', :id => @parent, :parent_type => @parent_type
  end

  private
  def get_parent_object(params)
    if params[:parent_type] == "pool"
      return Pool.find(params[:id])
    elsif params[:parent_type] == "cloud_account"
      return ProviderAccount.find(params[:id])
    end
    #TODO Throw no match to pool or cloud account exception
  end

  def get_parent_name(parent, parent_type)
    if parent_type == "pool"
      return parent.name
    elsif parent_type == "cloud_account"
      return parent.username
    end
    #TODO Throw no match to pool or cloud account exception
  end

  def check_params_infinite_limits(params)
    params.each_pair do |key, value|
      if value == ""
        params[key] = Quota::NO_LIMIT
      end
    end
    return params
  end


end
