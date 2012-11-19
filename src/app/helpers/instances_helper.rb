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

module InstancesHelper
  def instances_header
    [
      {:name => 'checkbox', :class => 'checkbox', :sortable => false },
      {:name => '', :class => 'alert', :sortable => false },
      {:name => _("Name"), :sortable => false },
      {:name => _("Public Address"), :sortable => false },
      {:name => _("State"), :sortable => false },
      {:name => _("Provider"), :sortable => false },
      {:name => _("Owner"), :sortable => false }
    ]
  end

  def api_instances_collection_href(deployment = nil)
    if deployment
      api_deployment_instances_url(deployment)
    else
      api_instances_url
    end
  end
end
