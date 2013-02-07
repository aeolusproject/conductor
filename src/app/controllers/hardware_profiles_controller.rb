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

class HardwareProfilesController < ApplicationController
  before_filter :require_user
  before_filter :load_hardware_profiles, :only => [:index, :show]
  before_filter :setup_new_hardware_profile, :only => [:new]
  before_filter :setup_hardware_profile, :only => [:new, :create, :matching_provider_hardware_profiles, :edit, :update]
  before_filter :set_edit_cost_variables, :only => [:edit_cost_billing, :edit_cost]

  def index
    @title = _('Hardware Profiles')
    clear_breadcrumbs
    save_breadcrumb(hardware_profiles_path)
    @params = params
    set_admin_content_tabs 'hardware_profiles'
    respond_to do |format|
      format.xml
      format.html
      format.js do
        if params[:hardware_profile]
          build_hardware_profile(params[:hardware_profile])
          find_matching_provider_hardware_profiles
          render :partial => 'matching_provider_hardware_profiles'
        else
          render :partial => 'list'
        end
      end
    end
  end

  def show
    @hardware_profile = HardwareProfile.find(Array(params[:id]).first)
    require_privilege(Privilege::VIEW, @hardware_profile)
    @title = if @hardware_profile.provider_hardware_profile?
               _('%s (Provider)') % @hardware_profile.name
             else
               _('%s (Front End)') % @hardware_profile.name
             end

    @tab_captions = [_('Properties'), _('History'), _('Matching Provider Hardware Profiles')]
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    properties
    @details_tab = 'properties' unless['properties', 'history',
                                       'matching_provider_hardware_profiles'].include?(@details_tab)
    find_matching_provider_hardware_profiles
    save_breadcrumb(hardware_profile_path(@hardware_profile), @hardware_profile.name)

    respond_to do |format|
      format.xml
      format.html
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
    end
  end

  def new
    require_privilege(Privilege::CREATE, HardwareProfile)
    @title = _('New Hardware Profile')

    respond_to do |format|
      format.html { render :action => 'new'}
      format.js { render :partial => 'matching_provider_hardware_profiles' }
    end
  end

  def create
    require_privilege(Privilege::CREATE, HardwareProfile)

    build_hardware_profile(params[:hardware_profile])

    if params[:commit] == _('Check Matches')
      find_matching_provider_hardware_profiles
      render :new and return
    end

    respond_to do |format|
      if @hardware_profile.save
        format.html { redirect_to hardware_profiles_path }
        format.xml  { render :show, :status => :created }
      else
        format.html { render :action => 'new' }
        format.xml  { render :template => 'api/validation_error',
                             :locals => { :errors => @hardware_profile.errors },
                             :status => :unprocessable_entity }
      end
    end
  end

  def matching_provider_hardware_profiles
    require_privilege(Privilege::CREATE, HardwareProfile)

    build_hardware_profile(params[:hardware_profile])
    find_matching_provider_hardware_profiles
    render :action => 'new'
  end

  def destroy
    @hardware_profile = HardwareProfile.find(params[:id])
    require_privilege(Privilege::MODIFY, @hardware_profile)

    if @hardware_profile.provider_hardware_profile?
      error_message = _('Cannot delete Provider Hardware Profiles')
      respond_to do |format|
        format.html do
          flash[:warning] = error_message
          redirect_to hardware_profile_path(@hardware_profile)
        end
        format.xml do
          raise Aeolus::Conductor::API::Error.new(403, error_message)
        end
      end
      return
    end

    respond_to do |format|
      if @hardware_profile.destroy
        format.html do
          flash[:notice] = _('Hardware profile was deleted')
          redirect_to hardware_profiles_path
        end
        format.xml { render :nothing => true, :status => :no_content }
      else
        format.html do
          flash[:error] = _('Hardware profile was not deleted')
          redirect_to hardware_profiles_path
        end
        format.xml do
          raise Aeolus::Conductor::API::Error.new(500, @hardware_profile.errors.full_messages.join(', '))
        end
      end
    end
  end

  def edit
    unless @hardware_profile
      @hardware_profile = HardwareProfile.find(params[:id])
    end
    require_privilege(Privilege::MODIFY, @hardware_profile)
    @title = @hardware_profile.name.titlecase
    if @hardware_profile.provider_hardware_profile?
      flash[:warning] = _('Cannot modify Provider Hardware Profiles')
      redirect_to hardware_profile_path(@hardware_profile)
      return
    end
    find_matching_provider_hardware_profiles
  end

  def update
    if params[:id]
      @hardware_profile = HardwareProfile.find(params[:id])
      require_privilege(Privilege::MODIFY, @hardware_profile)
      build_hardware_profile(params[:hardware_profile])
    end

    if params[:commit] == _('Check Matches')
      require_privilege(Privilege::VIEW, HardwareProfile)
      find_matching_provider_hardware_profiles
      render :edit and return
    end

    unless @hardware_profile.save
      render :action => 'edit' and return
    else
      flash[:notice] = _('Hardware Profile updated')
      redirect_to hardware_profiles_path
    end
  end

  def multi_destroy
    deleted=[]
    not_deleted=[]

    HardwareProfile.find(params[:hardware_profile_selected]).each do |hwp|
      if check_privilege(Privilege::MODIFY, hwp) && hwp.destroy
        deleted << hwp.name
      else
        not_deleted << hwp.name
      end
    end

    unless deleted.empty?
      flash[:notice] = t('hardware_profiles.flash.notice.more_deleted', :count => deleted.count, :deleted => deleted.join(', '))
    end
    unless not_deleted.empty?
      flash[:error] = t('hardware_profiles.flash.error.not_deleted_perms', :count => not_deleted.count, :not_deleted => not_deleted.join(', '))
    end

    redirect_to hardware_profiles_path
  end

  def filter
    redirect_to_original({"hardware_profiles_preset_filter" => params[:hardware_profiles_preset_filter], "hardware_profiles_search" => params[:hardware_profiles_search]})
  end

  def update_cost_billing
    redirect_to hardware_profiles_path unless params[:id]

    @hardware_profile = HardwareProfile.find(params[:id])
    require_privilege(Privilege::MODIFY, @hardware_profile)

    begin
      Cost.transaction do
        # terminate profile cost that exists atm
        @hardware_profile.close_costs(false)

        # set hardware profile cost
        Cost.create!(
          :chargeable_id   => @hardware_profile.id,
          :chargeable_type => CostEngine::CHARGEABLE_TYPES[:hardware_profile],
          :price           => 0,
          :valid_from      => Time.now(),
          :valid_to        => nil,
          :billing_model   => params[:cost][:billing_model]
        )

        flash[:notice] = _('Hardware Profile cost updated')
      end
      redirect_to edit_cost_hardware_profile_path(@hardware_profile)
    rescue Exception => ex
      flash[:error] = _('Failed to update Hardware Profile cost %s') % ex.message
      log_backtrace(ex)
      set_edit_cost_variables
      render :action => 'edit_cost_billing'
    end
  end

  def update_cost
    redirect_to hardware_profiles_path unless params[:id]

    @hardware_profile = HardwareProfile.find(params[:id])
    require_privilege(Privilege::MODIFY, @hardware_profile)

    begin
      Cost.transaction do
        # terminate costs that exist atm
        @hardware_profile.close_costs

        # set hardware profile cost
        Cost.create!(
          :chargeable_id   => @hardware_profile.id,
          :chargeable_type => CostEngine::CHARGEABLE_TYPES[:hardware_profile],
          :price           => (params[:cost][:price] rescue 0),
          :valid_from      => Time.now(),
          :valid_to        => nil,
          :billing_model   => billing_model = params[:cost][:billing_model]
        )

        if billing_model == 'per_property'
          # set hardware profile properties costs
          HardwareProfile::chargeables.each do |type|
            billing_model_param_name = type.to_s+'_billing_model'
            Cost.create!(
              :chargeable_id   => @hardware_profile.send((type.to_s+'_id').intern),
              :chargeable_type => CostEngine::CHARGEABLE_TYPES[('hw_'+type.to_s).intern],
              :price           => params[type.to_s+'_cost'],
              :valid_from      => Time.now(),
              :valid_to        => nil,
              :billing_model   => params[billing_model_param_name]
            ) unless params[billing_model_param_name] == 'none'
          end
        end
      end

      flash[:notice] = _('Hardware Profile cost updated')
      redirect_to hardware_profile_path(@hardware_profile)
    rescue Exception => ex
      flash[:error] = _('Failed to update Hardware Profile cost %s') % ex.message
      log_backtrace(ex)
      set_edit_cost_variables
      render :action => 'edit_cost'
    end
  end

  private
  def set_edit_cost_variables
    unless @hardware_profile
      @hardware_profile = HardwareProfile.find(params[:id])
    end
    require_privilege(Privilege::MODIFY, @hardware_profile)

    unless @hardware_profile.provider_hardware_profile?
      flash[:warning] = _('Cannot assign cost to Frontend Hardware Profile')
      redirect_to hardware_profile_path(@hardware_profile)
      return
    end

    @hwp_cost = @hardware_profile.cost_now || Cost.new(:billing_model => 'hour')
    @title = @hardware_profile.name.titlecase

    @header = [
      { :name => _('Name'),
        :sort_attr => :name},
      { :name => _('Billing Model'),
        :sort_attr => :billing_model},
      { :name => _('Cost per Unit'),
        :sort_attr => :cost}]

    @hwp_prop_costs = {}
    HardwareProfile::chargeables.each do |what|
      @hwp_prop_costs[what] = @hardware_profile.send(what).cost_now ||
                              Cost.new(:billing_model=>'none')
    end
  end

  def setup_new_hardware_profile
    if params[:hardware_profile]
      begin
        @hardware_profile = HardwareProfile.new(remove_irrelevant_params(params[:hardware_profile]))
      end
    else
      @hardware_profile = HardwareProfile.new(:memory => HardwareProfileProperty.new(:name => "memory", :unit => "MB"),
                                              :cpu => HardwareProfileProperty.new(:name => "cpu", :unit => "count"),
                                              :storage => HardwareProfileProperty.new(:name => "storage", :unit => "GB"),
                                              :architecture => HardwareProfileProperty.new(:name => "architecture", :unit => "label"))
    end
    find_matching_provider_hardware_profiles
  end

  def properties
    @properties_header = [
      { :name => _('Name'), :sort_attr => :name},
      { :name => _('Unit'), :sort_attr => :unit},
      { :name => _('Value'), :sort_attr => :value}]
    @properties_header << { :name => _('Cost per Unit'), :sort_attr => :value} if @hardware_profile.provider_hardware_profile?
    @hwp_properties = [@hardware_profile.memory, @hardware_profile.cpu, @hardware_profile.storage, @hardware_profile.architecture]
  end

  #TODO Update this method when moving to new HWP Model
  def find_matching_provider_hardware_profiles
    @provider_hwps_header = [
      { :name => _('Provider Name'), :sort_attr => "provider.name" },
      { :name => _('Hardware Profile Name'), :sort_attr => :name },
      { :name => _('Architecture'), :sort_attr => :architecture },
      { :name => _('Memory'), :sort_attr => :memory},
      { :name => _('Storage'), :sort_attr => :storage },
      { :name => _('Virtual CPU'), :sort_attr => :cpu},
      { :name => _('Minimal Cost'), :sort_attr => :cost}
    ]

    begin
      @matching_hwps = HardwareProfile.matching_hardware_profiles(@hardware_profile)
      @matching_hwps.reject! { |hwp| !check_privilege(Privilege::VIEW, hwp) }
    rescue Exception => e
      @matching_hwps = []
    end
  end

  def setup_hardware_profile
    @tab_captions = [_('Matching Provider Hardware Profiles')]
    @details_tab = 'matching_provider_hardware_profiles'
    @header  = [
      { :name => _('Name'), :sort_attr => :name},
      { :name => _('Unit'), :sort_attr => :unit},
      { :name => _('Minimum Value'), :sort_attr => :value}]
  end

  def load_hardware_profiles
    sort_order = sort_direction
    sort_field = sort_column(HardwareProfile, 'name')
    if sort_field == "name"
      @hardware_profiles = HardwareProfile.where('provider_id IS NULL', {}).
        apply_filters(:preset_filter_id =>
                        params[:hardware_profiles_preset_filter],
                      :search_filter => params[:hardware_profiles_search]).
        list_for_user(current_session, current_user, Privilege::VIEW).
        order("hardware_profiles.name #{sort_direction}")
    else
      @hardware_profiles = HardwareProfile.where('provider_id IS NULL', {}).
        apply_filters(:preset_filter_id =>
                        params[:hardware_profiles_preset_filter],
                      :search_filter => params[:hardware_profiles_search]).
        list_for_user(current_session, current_user, Privilege::VIEW)
      if sort_order == "asc"
        @hardware_profiles.sort! do |x,y|
          x.get_property_map[sort_field].sort_value(true) <=>
            y.get_property_map[sort_field].sort_value(true)
        end
      else
        @hardware_profiles.sort! do |x,y|
          y.get_property_map[sort_field].sort_value(false) <=>
            x.get_property_map[sort_field].sort_value(false)
        end
      end
    end

    @hardware_profiles.reject! { |hwp| !check_privilege(Privilege::VIEW, hwp) }
  end

  def build_hardware_profile(params)
    if @hardware_profile.nil?
      @hardware_profile = HardwareProfile.new
    end

    @hardware_profile.name = params[:name]
    @hardware_profile.memory = create_hwpp(@hardware_profile.memory, params[:memory_attributes])
    @hardware_profile.storage = create_hwpp(@hardware_profile.storage, params[:storage_attributes])
    @hardware_profile.cpu = create_hwpp(@hardware_profile.cpu, params[:cpu_attributes])
    @hardware_profile.architecture = create_hwpp(@hardware_profile.architecture, params[:architecture_attributes])
  end

  def create_hwpp(hwpp, params)
    hardwareProfileProperty = hwpp.nil? ? HardwareProfileProperty.new : hwpp

    hardwareProfileProperty.name = params[:name]
    hardwareProfileProperty.kind = "fixed"
    hardwareProfileProperty.value = params[:value]
    hardwareProfileProperty.unit = params[:unit]
    return hardwareProfileProperty
  end

end
