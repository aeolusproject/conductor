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
module ProviderRealmsHelper
  def provider_realms_header
    [
      {:name => t("realms.index.realm_name"), :sort_attr => :name},
      {:name => t("realms.index.realm_availability")}
    ]
  end

  def availability_label(available)
    available ? t('realms.index.realm_available.true_value') : t('realms.index.realm_available.false_value')
  end
end
