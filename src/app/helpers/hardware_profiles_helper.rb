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
module HardwareProfilesHelper
  def hardware_profiles_header
    [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => _("Hardware Profile Name"), :sort_attr => :name },
      { :name => _("Architecture"), :sort_attr => :architecture },
      { :name => _("Memory"), :class => 'center', :sort_attr => :memory},
      { :name => _("Storage"), :class => 'center', :sort_attr => :storage },
      { :name => _("Virtual CPU"), :class => 'center', :sort_attr => :cpu}
    ]
  end
end
