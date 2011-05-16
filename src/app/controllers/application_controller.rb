#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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


class ApplicationController < ActionController::Base
  # FIXME: not sure what we're doing aobut service layer w/ deltacloud
  include ApplicationService
  filter_parameter_logging :password, :password_confirmation
  helper_method :current_user_session, :current_user
  before_filter :shift_breadcrumbs
  layout 'old'

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
    log_error(hash[:error]) if hash[:error]
    msg = hash[:message] || hash[:error].message
    title = hash[:title] || "Internal Server Error"
    status = hash[:status] || :internal_server_error
    respond_to do |format|
      format.html { html_error_page(title, msg) }
      format.json { render :json => json_error_hash(msg, status) }
      format.xml { render :xml => xml_errors(msg), :status => status }
    end
  end

  def html_error_page(title, msg)
    if request.xhr?
      render :template => 'layouts/popup-error', :layout => 'popup',
             :locals => {:title => title, :errmsg => msg}
    else
      render :template => 'layouts/error', :layout => 'application',
             :locals => {:title => title, :errmsg => msg}
    end
  end

  # don't define find_opts for array inputs
  def json_hash(full_items, attributes, arg_list=[], find_opts={}, id_method=:id)
    page = params[:page].to_i
    paginate_opts = {:page => page,
                     :order => "#{params[:sortname]} #{params[:sortorder]}",
                     :per_page => params[:rp]}
    arg_list << find_opts.merge(paginate_opts)
    item_list = full_items.paginate(*arg_list)
    json_hash = {}
    json_hash[:page] = page
    json_hash[:total] = item_list.total_entries
    json_hash[:rows] = item_list.collect do |item|
      item_hash = {}
      item_hash[:id] = item.send(id_method)
      item_hash[:cell] = attributes.collect do |attr|
        if attr.is_a? Array
          value = item
          attr.each { |attr_item| value = (value.nil? ? nil : value.send(attr_item))}
          value
        else
          item.send(attr)
        end
      end
      item_hash
    end
    json_hash
  end

  # json_list is a helper method used to format data for paginated flexigrid tables
  #
  # FIXME: what is the intent of this comment? don't define find_opts for array inputs
  def json_list(full_items, attributes, arg_list=[], find_opts={}, id_method=:id)
    render :json => json_hash(full_items, attributes, arg_list, find_opts, id_method).to_json
  end

  def get_nav_items
    if current_user.present?
      @providers = Provider.list_for_user(@current_user, Privilege::VIEW)
      @pools = Pool.list_for_user(@current_user, Privilege::VIEW)
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
      return params[:id].to_a
    elsif params[:ids].present?
      return params[:ids].to_a
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

  def current_user_session
    return @current_user_session unless @current_user_session.nil?
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user unless @current_user.nil?
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    return if current_user
    store_location
    flash[:notice] = "You must be logged in to access this page"
    redirect_to login_url
  end

  def require_no_user
    return unless current_user
    store_location
    flash[:notice] = "You must be logged out to access this page"
    redirect_to account_url
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(default || session[:return_to])
    session[:return_to] = nil
  end

  def shift_breadcrumbs
    session[:breadcrumbs] ||= []
    shifted_breadcrumb = session[:breadcrumbs].shift unless session[:breadcrumbs].length < 3 || request.request_uri == session[:breadcrumbs].last[:path]
    #TODO waiting for the ViewState to be implemented
    #ViewState.find(shifted_breadcrumb[:viewstate]).mark_for_deletion if shifted_breadcrumb[:viewstate]
  end

  def save_breadcrumb(path, name = controller_name)
    session[:breadcrumbs] ||= []
    breadcrumbs = session[:breadcrumbs]
    viewstate = @viewstate ? @viewstate.id : nil

    if breadcrumbs.empty? or path != breadcrumbs.last[:path]
      breadcrumbs.push({:name => name, :path => path, :viewstate => viewstate})
    end

    session[:breadcrumbs] = breadcrumbs
  end
end
