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

require 'viewstate.rb'

class ApplicationController < ActionController::Base
  # FIXME: not sure what we're doing aobut service layer w/ deltacloud
  include ApplicationService
  helper_method :current_user, :filter_view?
  before_filter :read_breadcrumbs, :set_locale

  # General error handlers, must be in order from least specific
  # to most specific
  rescue_from Exception, :with => :handle_general_error
  rescue_from PermissionError, :with => :handle_perm_error
  rescue_from ActionError, :with => :handle_action_error
  rescue_from PartialSuccessError, :with => :handle_partial_success_error
  rescue_from ActiveRecord::RecordNotFound, :with => :handle_active_record_not_found_error
  rescue_from Aeolus::Conductor::API::Error, :with => :handle_api_error

  helper_method :check_privilege

  protected

  # permissions checking

  def handle_perm_error(error)
    handle_error(:error => error, :status => :forbidden,
                 :title => t('application_controller.access_denied'))
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
                 :title => t('application_controller.some_actions_failed'))
  end

  def handle_action_error(error)
    handle_error(:error => error, :status => :conflict,
                 :title => t('application_controller.action_error'))
  end

  def handle_general_error(error)
    flash[:errmsg] = error.message
    handle_error(:error => error, :status => :internal_server_error,
                 :title => t('application_controller.internal_server_error'))
  end

  def handle_error(hash)
    logger.fatal(hash[:error].to_s) if hash[:error]
    logger.fatal(hash[:error].backtrace.join("\n ")) if hash[:error]
    msg = hash[:message] || hash[:error].message
    title = hash[:title] || t('application_controller.internal_server_error')
    status = hash[:status] || t('application_controller.internal_server_error')
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
    flash[:notice] = t('application_controller.flash.notice.record_not_exist')
  end

  def handle_api_error(error)
    render :template => 'api/error', :locals => {:error => error}, :status => error.status
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
        flash[:notice] = t('application_controller.flash.notice.must_be_logged')
        redirect_to login_url
      end
      format.xml { head :unauthorized }
      format.json { render :json => "You must be logged in to access this page" }
    end
  end

  def require_user_api
    return if current_user or http_auth_user
    respond_to do |format|
      format.xml { head :unauthorized }
    end
  end

  def require_no_user
    return true unless current_user
    store_location
    flash[:notice] = t('application_controller.flash.notice.must_not_be_logged')
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

  def set_admin_content_tabs(tab)
    @tabs = [{:name => t('application_controller.admin_tabs.catalogs'), :url => catalogs_url, :id => 'catalogs'},
             {:name => t('application_controller.admin_tabs.realms'), :url => realms_url, :id => 'realms'},
             {:name => t('application_controller.admin_tabs.hardware'), :url => hardware_profiles_url, :id => 'hardware_profiles'},
    ]
    unless @details_tab = @tabs.find {|t| t[:id] == tab}
      raise "Tab '#{tab}' doesn't exist"
    end
  end

  def set_admin_users_tabs(tab)
    @tabs = [{:name => t('application_controller.admin_tabs.users'), :url => users_url, :id => 'users'},
             #{:name => t('application_controller.admin_tabs.groups'), :url => groups_url, :id => 'groups'},
             {:name => t('application_controller.admin_tabs.permissions'), :url => permissions_url, :id => 'permissions'},
    ]
    unless @details_tab = @tabs.find {|t| t[:id] == tab}
      raise "Tab '#{tab}' doesn't exist"
    end
  end

  def set_admin_environments_tabs(tab)
    @tabs = [{:name => t('application_controller.admin_tabs.pool_families'), :url => pool_families_url, :id => 'pool_families'},
             {:name => t('application_controller.admin_tabs.images'), :url => images_url, :id => 'images'},
    ]
    unless @details_tab = @tabs.find {|t| t[:id] == tab}
      raise "Tab '#{tab}' doesn't exist"
    end
  end

  def sort_column(model, default="name")
    model.column_names.include?(params[:order_field]) ? params[:order_field] : default
  end

  def sort_direction
    %w[asc desc].include?(params[:order_dir]) ? params[:order_dir] : "asc"
  end

  def add_permissions_inline(perm_obj, path_prefix = "")
    @permission_object = perm_obj
    @path_prefix = path_prefix
    @roles = Role.find_all_by_scope(@permission_object.class.name)
    set_permissions_header
  end

  def add_permissions_tab(perm_obj, path_prefix = "")
    @path_prefix = path_prefix
    if "permissions" == params[:details_tab]
      require_privilege(Privilege::PERM_VIEW, perm_obj)
      @permission_object = perm_obj
    end
    if perm_obj.has_privilege(current_user, Privilege::PERM_VIEW)
      @roles = Role.find_all_by_scope(@permission_object.class.name)
      if @tabs
        @tabs << {:name => t('users.users'),
                  :view => 'permissions',
                  :id => 'permissions',
                  :count => perm_obj.permissions.count}
      end
    end
    set_permissions_header
  end

  def set_permissions_header
    @permission_list_header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t('users.index.username') },
      { :name => t('users.index.last_name'), :sortable => false },
      { :name => t('users.index.first_name'), :sortable => false },
      { :name => t("role"), :sort_attr => :role},
    ]
  end

  # Try to clean up and internationalize certain errors we get from other components
  # Accepts a string or an Exception
  def humanize_error(error, options={})
    error = error.message if error.is_a?(Exception)
    if error.match("Connection refused - connect\\(2\\)")
      if options[:context] == :deltacloud
        return t('deltacloud.unreachable')
      else
        return t('connection_refused')
      end
    else
      # Nothing else matched
      error
    end
  end

  def set_locale
    I18n.locale = env.nil? || env['HTTP_ACCEPT_LANGUAGE'].nil? ? I18n.default_locale : detect_locale
  end

  def detect_locale
    languages = env['HTTP_ACCEPT_LANGUAGE'].split(',')
    prefs = []
    languages.each do |language|
      language += ";q=1.0" unless language.match(";q=\d+\.\d+")
      lang_code, lang_weight = language.split(";q=")
      lang_code = lang_code.gsub(/-[a-z]+$/i) { |x| x.upcase }.to_sym
      prefs << [lang_weight, lang_code]
    end
    # This is slightly abusing array sorting
    ordered_languages = prefs.sort.reverse.collect{|p| p[1]}

    (ordered_languages & I18n.available_locales).first
  end
end
