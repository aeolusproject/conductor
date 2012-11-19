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

class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  layout 'login'

  def new
    @title = _("Login")
  end

  def create
    authenticate!
    session[:javascript_enabled] = request.xhr?
    respond_to do |format|
      format.html { redirect_to back_or_default_url(root_url) }
      format.js { render :js => "window.location.href = '#{back_or_default_url root_url}'" }
    end
  end

  def unauthenticated
    Rails.logger.warn "Request is unauthenticated for #{request.remote_ip}"

    respond_to do |format|
      format.xml { head :unauthorized }
      format.html do
        flash.now[:warning] = _("The Username or Password is incorrect, please try again.")
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
