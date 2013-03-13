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

module DeploymentsHelper
  def api_deployments_collection_href(pool = nil)
    if pool
      api_pool_deployments_url(pool)
    else
      api_deployments_url
    end
  end

  def translate_state_description(state)
    case state
      when Deployment::STATE_NEW
        _('Deployment wasn\'t started')
      when Deployment::STATE_PENDING
        _('Deployment is starting up')
      when Deployment::STATE_RUNNING
        _('All Instances are running')
      when Deployment::STATE_INCOMPLETE
        _('Some Instances are not running')
      when Deployment::STATE_SHUTTING_DOWN
        _('Deployment is shutting down')
      when Deployment::STATE_STOPPED
        _('All Instances are stopped')
      when Deployment::STATE_FAILED
        _('All Instances are in failed state')
      when Deployment::STATE_ROLLBACK_IN_PROGRESS
        _('Launch failed, rollback is in progress')
      when Deployment::STATE_ROLLBACK_COMPLETE
        _('Rollback successfully completed')
      when Deployment::STATE_ROLLBACK_FAILED
        _('Rollback failed, re-launch terminated')
    end
  end
end
