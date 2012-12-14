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

module QuotaAware

  # In XML requests, the quota is embedded as 'qouta' node
  # In UI requests, the quota is embedded as 'quota_attributes' node because it is treated
  # as a nested resource.
  def transform_quota_param(model_name)
    if !params[model_name][:quota].nil?
      params[model_name][:quota_attributes] = params[model_name][:quota]
      params[model_name].delete(:quota)
    end

    if params[:unlimited_quota].present? && params[model_name].has_key?(:quota_attributes)
      params[model_name][:quota_attributes][:maximum_running_instances] = nil
    end
  end

end
