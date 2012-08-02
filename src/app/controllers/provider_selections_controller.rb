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

  def show
    @pool = Pool.find(params[:pool_id])
    @environment = @pool.pool_family
    @available_strategies = ProviderSelection::Base.strategies
  end

  def toggle_strategy
    pool = Pool.find(params[:pool_id])
    strategy = ProviderSelection::Base.find_strategy_by_name(params[:strategy_name])

    if pool.provider_selection_strategies.exists?(:name => strategy.name)
      provider_selection_strategy = pool.provider_selection_strategies.find_by_name(strategy.name)
      provider_selection_strategy.enabled = !provider_selection_strategy.enabled
    else
      provider_selection_strategy =
          ProviderSelectionStrategy.new(:name => strategy.name,
                                        :enabled => true,
                                        :pool => pool)
    end

    if provider_selection_strategy.save
      notice =
        if provider_selection_strategy.enabled
          t('provider_selection.flash.successfully_enabled', :strategy_name => strategy.translated_name)
        else
          t('provider_selection.flash.successfully_disabled', :strategy_name => strategy.translated_name)
        end

      redirect_to :back, :notice => notice
    else
      notice =
        if provider_selection_strategy.enabled
          t('provider_selection.flash.failed_to_enable', :strategy_name => strategy.translated_name)
        else
          t('provider_selection.flash.failed_to_disable', :strategy_name => strategy.translated_name)
        end

      redirect_to :back, :notice => notice
    end
  end

  private

  def set_view_path
    ProviderSelection::Base.view_paths.each do |view_path|
      append_view_path(view_path)
    end
  end

end