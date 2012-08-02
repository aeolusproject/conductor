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

# Require strategies
Dir['vendor/provider_selection/strategies/*/'].each do |path|
  strategy_name = File.basename(path)
  strategy_lib_path = File.expand_path(File.join(path, "#{strategy_name}.rb"))
  ProviderSelection::Base.register_strategy(strategy_name, strategy_lib_path)
end

# Register view path
#ProviderSelection::Base.add_view_path(File.expand_path(File.join('vendor', 'provider_selection', 'views')))

# Extend I18n.load_path
#I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'config', 'locales', '*.yml')]
