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

Tim.user_class = "User"
Tim.provider_account_class = "ProviderAccount"
Tim.provider_type_class = "ProviderType"
Tim::ImageFactory::Base.site = SETTINGS_CONFIG[:imagefactory][:url]
Tim::ImageFactory::TargetImage.callback_url = SETTINGS_CONFIG[:imagefactory][:callback_urls][:target_image]
Tim::ImageFactory::ProviderImage.callback_url = SETTINGS_CONFIG[:imagefactory][:callback_urls][:provider_image]
