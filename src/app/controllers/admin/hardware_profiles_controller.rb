class Admin::HardwareProfilesController < ApplicationController
  before_filter :require_user
  before_filter :load_hardware_profiles, :only => [:index, :show]
  before_filter :load_hardware_profile, :only => [:show]
  def index
  end

  def show
    @tab_captions = ['Properties', 'History', 'Matching Provider Hardware Profiles']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]
    case @details_tab
      when 'properties'
        properties
      when 'matching_provider_hardware_profiles'
        matching_provider_hardware_profiles
    end
    respond_to do |format|
      format.js do
        if @url_params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show'}
    end
  end

  def new
  end

  def create
  end

  def delete
  end

  private
  def properties
    @properties_header = [
      { :name => "Name", :sort_attr => :name},
      { :name => "Kind", :sort_attr => :kind },
      { :name => "Range First", :sort_attr => :range_first},
      { :name => "Range Last", :sort_attr => :range_last },
      { :name => "Enum Entries", :sort_attr => :false },
      { :name => "Default Value", :sort_attr => :value},
      { :name => "Unit", :sort_attr => :unit}
      ]
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
      { :name => "Virtual CPU", :sort_attr => :cpus}
    ]
    @matching_hwps = HardwareProfile.all(:include => "aggregator_hardware_profiles",
                                         :conditions => {:hardware_profile_map => { :aggregator_hardware_profile_id => params[:id] }})
  end

  def load_hardware_profiles
    @hardware_profiles = HardwareProfile.all(:conditions => 'provider_id IS NULL')
    @url_params = params
    @header = [
      { :name => "Hardware Profile Name", :sort_attr => :name },
      { :name => "Architecture", :sort_attr => :architecture },
      { :name => "Memory", :sort_attr => :memory},
      { :name => "Storage", :sort_attr => :storage },
      { :name => "Virtual CPU", :sort_attr => :cpus}
    ]
  end

  def load_hardware_profile
    @hardware_profile = HardwareProfile.find((params[:id] || []).first)
  end

end