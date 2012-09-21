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

class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  layout 'converge-ui/login_layout'

  def new
    @title = t('masthead.login')
    @disable_password_recovery = true
  end

  def create
    authenticate!
    session[:javascript_enabled] = request.xhr?
    respond_to do |format|
      format.html do
        redirect_to back_or_default_url(root_url)
      end
      format.js do
        render :js => "window.location.href = '#{back_or_default_url root_url}'"
      end
    end
  end

  def unauthenticated
    Rails.logger.warn "Request is unauthenticated for #{request.remote_ip}"
    @disable_password_recovery = true

    respond_to do |format|
      format.xml { head :unauthorized }
      format.html do
        flash.now[:warning] = t "user_sessions.flash.warning.login_failed"
        render :action => :new
      end
      format.js { head :unauthorized }
    end
  end

  def destroy
    clear_breadcrumbs
    logout
    redirect_to login_url
  end
end
