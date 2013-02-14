#
#   Copyright 2012 Red Hat, Inc.
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

class ProviderSelectionsController < ApplicationController

  before_filter :require_user
  before_filter :set_view_path
  before_filter :load_pool
  before_filter :require_privileged_user_for_modify, :except => :show

  def show
    require_privilege(Privilege::VIEW, @pool)

    @environment = @pool.pool_family
    @available_strategies = ProviderSelection::Base.strategies
  end

  def toggle_strategy
    strategy = ProviderSelection::Base.find_strategy_by_name(params[:strategy_name])

    if @pool.provider_selection_strategies.exists?(:name => strategy.name)
      provider_selection_strategy = @pool.provider_selection_strategies.find_by_name(strategy.name)
      provider_selection_strategy.enabled = !provider_selection_strategy.enabled
    else
      provider_selection_strategy =
          ProviderSelectionStrategy.new(:name => strategy.name,
                                        :enabled => true,
                                        :pool => @pool)
    end

    if provider_selection_strategy.save
      notice =
        if provider_selection_strategy.enabled
          _('Successfully enabled %s strategy') % strategy.translated_name
        else
          _('Successfully disabled %s strategy') % strategy.translated_name
        end

      redirect_to :back, :notice => notice
    else
      notice =
        if provider_selection_strategy.enabled
          _('Failed to enable %s strategy') % strategy.translated_name
        else
          _('Failed to disable %s strategy') % strategy.translated_name
        end

      redirect_to :back, :notice => notice
    end
  end

  def edit_strategy
    @strategy = ProviderSelection::Base.find_strategy_by_name(params[:strategy_name])
    @provider_selection_strategy = @pool.provider_selection_strategies.find_by_name(@strategy.name)
    @config = @strategy.base_klass.properties[:config_klass].new(@provider_selection_strategy.config)
    @edit_partial = @strategy.base_klass.properties[:edit_partial]
  end

  def save_strategy_options
    @strategy = ProviderSelection::Base.find_strategy_by_name(params[:strategy_name])
    @config = @strategy.base_klass.properties[:config_klass].new(params[:config])

    if @config.valid?
      @provider_selection_strategy = @pool.provider_selection_strategies.find_by_name(@strategy.name)
      @provider_selection_strategy.update_attributes(:config => @config.to_hash)

      redirect_to pool_provider_selection_path(@pool),
                  :notice => _('Successfully updated %s strategy') % @strategy.translated_name
    else
      @edit_partial = @strategy.base_klass.properties[:edit_partial]
      render :edit_strategy
    end
  end

  private

  def set_view_path
    ProviderSelection::Base.view_paths.each do |view_path|
      append_view_path(view_path)
    end
  end

  def load_pool
    @pool = Pool.find(params[:pool_id])
  end

  def require_privileged_user_for_modify
    require_privilege(Privilege::MODIFY, @pool)
  end

end
