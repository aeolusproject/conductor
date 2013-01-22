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

class UsernameRecoveriesController < ApplicationController
  before_filter :require_no_user
  layout 'login'

  def create
    users_ids = User.find_all_by_email(params[:email]).map(&:id)
    UserMailer.delay.send_usernames(users_ids) unless users_ids.blank?
    respond_to do |format|
      # note: for security reasons we provide success message even if incorrect/non-existent email is filled in.
      format.html { redirect_to login_path, :notice => _("Usernames have been sent to given e-mail address.") }
      format.js do
        flash.now[:notice] = _("Usernames have been sent to given e-mail address.")
      end
    end
  end
end
