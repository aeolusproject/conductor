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
module ProviderSelectionsHelper

  def strategy_toggle_state(strategy)
    provider_selection_strategy = @pool.provider_selection_strategies.find_by_name(strategy.name)
    if provider_selection_strategy.present? && provider_selection_strategy.enabled
      'on'
    else
      'off'
    end
  end

  def strategy_actions(strategy)
    provider_selection_strategy = @pool.provider_selection_strategies.find_by_name(strategy.name)
    if provider_selection_strategy.present? && provider_selection_strategy.enabled
      if strategy.base_klass.properties.has_key?(:edit_path)
        strategy_edit_path = send(strategy.base_klass.properties[:edit_path])
        link_to(_("Configure"), strategy_edit_path, :class => 'button')
      elsif strategy.base_klass.properties.has_key?(:config_klass)
        strategy_edit_path = edit_strategy_pool_provider_selection_path(@pool, strategy.name)
        link_to(_("Configure"), strategy_edit_path, :class => 'button')
      end
    end
  end

end
