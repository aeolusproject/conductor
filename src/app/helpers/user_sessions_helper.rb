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

module UserSessionsHelper
  # this overrides the rails_translations and translations helpers from converge ui
  # should be removed when those two helpers are fixed in converge-ui
  @@translations = {
    :show_password            => I18n.t("user_sessions.new.show_password"),
    :example_logo             => I18n.t("logo"),
    :forgot_username_password => I18n.t("user_sessions.new.forgot_username_password"),
    :username                 => I18n.t("user_sessions.new.username"),
    :password                 => I18n.t("user_sessions.new.password"),
    :login                    => I18n.t("user_sessions.new.login"),
    :recovery_link            => I18n.t("Forgot %s or %s?")
  }

  def get_string(text_key)
    return @@translations[text_key]
  end
end
