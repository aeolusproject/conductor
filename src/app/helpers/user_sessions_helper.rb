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

module UserSessionsHelper
  # this overrides the rails_translations and translations helpers from converge ui
  # should be removed when those two helpers are fixed in converge-ui
  @@translations = {
    :noscript                 => "user_sessions.noscript",
    :username                 => "user_sessions.username",
    :password                 => "user_sessions.password",
    :login                    => "user_sessions.login",
    :recovery_link            => "user_sessions.recovery_link",
    :email_address            => "password_resets.email_address",
    :send_login               => "username_recoveries.recover_usernames",
    :password_unknown         => "password_resets.password_unknown",
    :password_unknown_info    => "password_resets.password_unknown_info",
    :reset_password           => "password_resets.reset_password",
    :username_unknown         => "username_recoveries.username_unknown",
    :username_unknown_info    => "username_recoveries.username_unknown_info",
    :change_password          => "password_resets.change_password",
    :change_password_info     => "password_resets.change_password_info",
    :new_password             => "password_resets.new_password",
    :confirm_password         => "password_resets.confirm_password",
    :passwords_do_not_match   => "user_sessions.passwords_do_not_match"
  }

  def get_string(text_key)
    return I18n.t @@translations[text_key]
  end
end
