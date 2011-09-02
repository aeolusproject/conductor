#
# Copyright (C) 2011 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'viewstate.rb'

class ApplicationController < ActionController::Base
  # FIXME: not sure what we're doing aobut service layer w/ deltacloud
  include ApplicationService
  helper_method :current_user, :filter_view?
  before_filter :read_breadcrumbs

  # General error handlers, must be in order from least specific
  # to most specific
  rescue_from Exception, :with => :handle_general_error
  rescue_from PermissionError, :with => :handle_perm_error
  rescue_from ActionError, :with => :handle_action_error
  rescue_from PartialSuccessError, :with => :handle_partial_success_error
  rescue_from ActiveRecord::RecordNotFound, :with => :handle_active_record_not_found_error

  helper_method :check_privilege

  protected
  # permissions checking

  def handle_perm_error(error)
    handle_error(:error => error, :status => :forbidden,
                 :title => "Access denied")
  end

  def handle_partial_success_error(error)
    failures_arr = error.failures.collect do |resource, reason|
      if resource.respond_to?(:display_name)
        resource.display_name + ": " + reason
      else
        reason
      end
    end
    @successes = error.successes
    @failures = error.failures
    handle_error(:error => error, :status => :ok,
                 :message => error.message + ": " + failures_arr.join(", "),
                 :title => "Some actions failed")
  end

  def handle_action_error(error)
    handle_error(:error => error, :status => :conflict,
                 :title => "Action Error")
  end

  def handle_general_error(error)
    flash[:errmsg] = error.message
    handle_error(:error => error, :status => :internal_server_error,
                 :title => "Internal Server Error")
  end

  def handle_error(hash)
    logger.fatal(hash[:error].to_s) if hash[:error]
    logger.fatal(hash[:error].backtrace.join("\n ")) if hash[:error]
    msg = hash[:message] || hash[:error].message
    title = hash[:title] || "Internal Server Error"
    status = hash[:status] || :internal_server_error
    respond_to do |format|
      format.html { html_error_page(title, msg, status) }
      format.json { render :json => json_error_hash(msg, status) }
      format.xml { render :xml => xml_errors(msg), :status => status }
    end
  end

  def html_error_page(title, msg, status)
    if request.xhr?
      render :template => 'layouts/popup-error', :layout => 'popup', :status => status,
             :locals => {:title => title, :errmsg => msg}
    else
      render :template => 'layouts/error', :layout => 'application',
             :locals => {:title => title, :errmsg => msg}
    end
  end

  def get_nav_items
    if current_user.present?
      @providers = Provider.list_for_user(current_user, Privilege::VIEW)
      @pools = Pool.list_for_user(current_user, Privilege::VIEW)
    end
  end

  def handle_active_record_not_found_error(error)
    redirect_to :controller => params[:controller]
    flash[:notice] = "The record you tried to access does not exist, it may have been deleted"
  end

  # Returns an array of ids from params[:id], params[:ids].
  def ids_list(other_attrs=[])
    other_attrs.each do |attr_key|
      return params[attr_key].to_a if params.include?(attr_key)
    end
    if params[:id].present?
      return Array(params[:id])
    elsif params[:ids].present?
      return Array(params[:ids])
    end
  end

  # let's suppose that 'pretty' view is default
  def filter_view?
    if @viewstate
      @viewstate.state['view'] == 'filter'
    else
      params[:view] == 'filter'
    end
  end

  private
  def json_error_hash(msg, status)
    json = {}
    json[:success] = (status == :ok)
    json.merge!(instance_errors)
    # There's a potential issue here: if we add :errors for an object
    # that the view won't generate inline error messages for, the user
    # won't get any indication what the error is. But if we set :alert
    # unconditionally, the user will get validation errors twice: once
    # inline in the form, and once in the flash
    json[:alert] = msg unless json[:errors]
    return json
  end

  def xml_errors(msg)
    xml = {}
    xml[:message] = msg
    xml.merge!(instance_errors)
    return xml
  end

  def instance_errors
    hash = {}
    arr = Array.new
    instance_variables.each do |ivar|
      val = instance_variable_get(ivar)
      if val && val.respond_to?(:errors) && val.errors.size > 0
        hash[:object] = ivar[1, ivar.size]
        hash[:errors] ||= []
        val.errors.each {|key,msg|
          arr.push([key, msg.to_a].to_a)
        }
        hash[:errors] += arr
      end
    end
    return hash
  end

  def http_auth_user
    return unless request.authorization && request.authorization =~ /^Basic (.*)/m
    authenticate!(:scope => :api)
    # we use :api scope for authentication to avoid saving session.
    # But it's handy to set authenticated user in default scope, so we
    # can use current_user, instead of current_user(:api)
    env['warden'].set_user(user(:api)) if user(:api)
    return user(:api)
  end

  def require_user
    return if current_user or http_auth_user
    respond_to do |format|
      format.html do
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to login_url
      end
      format.xml { head :unauthorized }
      format.json { render :json => "You must be logged in to access this page" }
    end
  end

  def require_no_user
    return true unless current_user
    store_location
    flash[:notice] = "You must be logged out to access this page"
    redirect_to account_url
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(default || session[:return_to])
    session[:return_to] = nil
  end

  ############################################################################
  # Breadcrumb-Related functionality
  ############################################################################

  def read_breadcrumbs
    session[:breadcrumbs] ||= []
    @read_breadcrumbs = session[:breadcrumbs].last(2)
  end

  def clear_breadcrumbs
    session[:breadcrumbs] = []
  end

  def save_breadcrumb(path, name = controller_name)
    session[:breadcrumbs] ||= []
    breadcrumbs = session[:breadcrumbs]
    viewstate = @viewstate ? @viewstate.id : nil

    #if item with desired path is already in bc, then remove every bc behind it
    if index = breadcrumbs.find_index {|b| b[:path] == path || path.split('?')[0] == b[:path] }
      breadcrumbs.slice!(index, breadcrumbs.length)
    end
    read_breadcrumbs
    breadcrumbs.push({:name => name, :path => path, :viewstate => viewstate, :class => controller_name})

    session[:breadcrumbs] = breadcrumbs
  end

end
