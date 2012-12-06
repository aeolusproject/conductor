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

class PasswordResetsController < ApplicationController
  before_filter :require_no_user
  before_filter :find_user_by_reset_token, :only => [:edit, :update]
  layout 'login'

  def create
    user = User.find_by_username_and_email(params[:username], params[:email])
    user.send_password_reset if user
    respond_to do |format|
      # note: for security reasons we provide success message even if incorrect/non-existent email/username combination is filled in.
      format.html{ redirect_to login_path, :notice => t("password_resets.reset_instructions_sent") }
      format.js do
        flash.now[:notice] = t("password_resets.reset_instructions_sent")
      end
    end
  end

  def edit
    respond_to do |format|
      if @user.password_reset_sent_at < SETTINGS_CONFIG[:action_mailer][:password_reset_token_timeout].minutes.ago
        format.html{ redirect_to new_user_sessions_path(:password_reset => true), :alert => t("password_resets.password_reset_expired") }
      else
        format.html
      end
    end
  end

  def update
    respond_to do |format|
      if @user.password_reset_sent_at < SETTINGS_CONFIG[:action_mailer][:password_reset_token_timeout].minutes.ago
        format.html{ redirect_to new_user_sessions_path(:password_reset => true), :alert => t("password_resets.password_reset_expired") }
      end

      # update the password and reset the 'password reset token' so that it cannot be reused
      params[:user][:password_reset_token]   = nil
      params[:user][:password_reset_sent_at] = nil

      if @user.update_attributes(params[:user])
        flash[:notice] = t("password_resets.password_reset_success")
        format.html{ redirect_to login_path }
        format.js { render :js => "window.location.href = '#{login_path}'" }
      else
        format.html{ render :edit }
        format.js { render :edit }
      end
    end
  end

  def find_user_by_reset_token
    @user = User.find_by_password_reset_token!(params[:id])
  rescue ActiveRecord::RecordNotFound => error
    flash[:notice] = t("password_resets.invalid_token")
    redirect_to login_path(:card => 'password_reset')
  end
end
