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
  layout 'login'

  def new
    @title = t('masthead.login')
  end

  def create
    authenticate!
    session[:javascript_enabled] = request.xhr?
    respond_to do |format|
      format.html do
        flash[:notice] = t"user_sessions.flash.notice.login"
        redirect_back_or_default root_url
      end
      format.js { render :status => 201, :text => session[:return_to] || root_url }
    end
  end

  def unauthenticated
    Rails.logger.warn "Request is unauthenticated for #{request.remote_ip}"

    respond_to do |format|
      format.xml { head :unauthorized }
      format.html do
        flash[:warning] = t"user_sessions.flash.warning.login_failed"
        render :action => :new
      end
      format.js { render :status=> 401, :text => "#{t('user_sessions.flash.warning.login_failed')}" }
    end

    return false
  end

  def destroy
    clear_breadcrumbs
    logout
    flash[:notice] = t"user_sessions.flash.notice.logout"
    redirect_back_or_default login_url
  end
end
