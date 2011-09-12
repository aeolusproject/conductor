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

class HardwareProfilesController < ApplicationController
  before_filter :require_user, :except => :matching_profiles
  before_filter :load_hardware_profiles, :only => [:index, :show]
  before_filter :load_hardware_profile, :only => [:show]
  before_filter :setup_new_hardware_profile, :only => [:new]
  before_filter :setup_hardware_profile, :only => [:new, :create, :edit, :update]

  def index
    clear_breadcrumbs
    save_breadcrumb(hardware_profiles_path)
    @params = params
    respond_to do |format|
      format.html { load_hardware_profiles }
      format.js do
        build_hardware_profile(params[:hardware_profile])
        matching_provider_hardware_profiles
        render :partial => 'matching_provider_hardware_profiles' and return
      end
    end
  end

  def show
    @hardware_profile = HardwareProfile.find(params[:id].to_a.first)
    require_privilege(Privilege::VIEW, @hardware_profile)

    @tab_captions = ['Properties', 'History', 'Matching Provider Hardware Profiles']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    properties
    matching_provider_hardware_profiles
    save_breadcrumb(hardware_profile_path(@hardware_profile), @hardware_profile.name)

    respond_to do |format|
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

    respond_to do |format|
      format.html { render :action => 'new'}
      format.js { render :partial => 'matching_provider_hardware_profiles' }
    end
  end

  def create
    require_privilege(Privilege::CREATE, HardwareProfile)

    build_hardware_profile(params[:hardware_profile])
    if params[:commit] == 'Save'
      if @hardware_profile.save
        redirect_to hardware_profiles_path
      else
        params.delete :commit
        render :action => 'new'
      end
    else
      matching_provider_hardware_profiles
      render :action => 'new'
    end
  end

  def destroy
    hardware_profile = HardwareProfile.find(params[:id])
    require_privilege(Privilege::MODIFY, hardware_profile)
    if hardware_profile.destroy
       flash[:notice] = "Hardware profile was deleted!"
    else
       flash[:error] = "Hardware profile was not deleted!"
    end
    redirect_to hardware_profiles_path
  end

  def edit
    unless @hardware_profile
      @hardware_profile = HardwareProfile.find(params[:id])
    end
    require_privilege(Privilege::MODIFY, @hardware_profile)
    matching_provider_hardware_profiles
  end

  def update
    if params[:id]
      @hardware_profile = HardwareProfile.find(params[:id])
      require_privilege(Privilege::MODIFY, @hardware_profile)
      build_hardware_profile(params[:hardware_profile])
    end

    if params[:commit] == "Check Matches"
      require_privilege(Privilege::VIEW, HardwareProfile)
      matching_provider_hardware_profiles
      render :edit and return
    end

    unless @hardware_profile.save
      render :action => 'edit' and return
    else
      flash[:notice] = "Hardware Profile updated!"
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
      flash[:notice] = "These Hardware Profiles were deleted: #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "Could not deleted these Hardware Profiles: #{not_deleted.join(', ')}"
    end

    redirect_to hardware_profiles_path
  end

  private
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
    matching_provider_hardware_profiles
  end

  def properties
    @properties_header = [
      { :name => "Name", :sort_attr => :name},
      { :name => "Unit", :sort_attr => :unit},
      { :name => "Minimum Value", :sort_attr => :value}]
    @hwp_properties = [@hardware_profile.memory, @hardware_profile.cpu, @hardware_profile.storage, @hardware_profile.architecture]
  end

  #TODO Update this method when moving to new HWP Model
  def matching_provider_hardware_profiles
    @provider_hwps_header  = [
      { :name => "Provider Name", :sort_attr => "provider.name" },
      { :name => "Hardware Profile Name", :sort_attr => :name },
      { :name => "Architecture", :sort_attr => :architecture },
      { :name => "Memory", :sort_attr => :memory},
      { :name => "Storage", :sort_attr => :storage },
      { :name => "Virtual CPU", :sort_attr => :cpu}
    ]

    begin
      @matching_hwps = HardwareProfile.matching_hardware_profiles(@hardware_profile)
    rescue Exception => e
      @matching_hwps = []
    end
  end

  def setup_hardware_profile
    @tab_captions = ['Matched Provider Hardware Profiles']
    @details_tab = 'matching_provider_hardware_profiles'
    @header  = [
      { :name => "Name", :sort_attr => :name},
      { :name => "Unit", :sort_attr => :unit},
      { :name => "Minimum Value", :sort_attr => :value}]
  end

  def load_hardware_profiles
    sort_field = params[:order_field].nil? ? "name" : params[:order_field]
    sort_order = params[:order_dir] == "asc" || params[:order_dir].nil? ? "" : "desc"
    if sort_field == "name"
      @hardware_profiles = HardwareProfile.all(:order => sort_field + " " + sort_order, :conditions => 'provider_id IS NULL')
    else
      @hardware_profiles = HardwareProfile.all(:conditions => 'provider_id IS NULL')
      if sort_order == ""
        @hardware_profiles.sort! {|x,y| x.get_property_map[sort_field].sort_value(true) <=> y.get_property_map[sort_field].sort_value(true)}
      else
        @hardware_profiles.sort! {|x,y| y.get_property_map[sort_field].sort_value(false) <=> x.get_property_map[sort_field].sort_value(false)}
      end
    end
  end

  def load_hardware_profile
    @hardware_profile = HardwareProfile.find(params[:id])
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
