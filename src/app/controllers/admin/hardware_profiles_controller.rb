class Admin::HardwareProfilesController < ApplicationController
  before_filter :require_user, :except => :matching_profiles
  before_filter :set_params_and_header, :only => [:index, :show]
  before_filter :load_hardware_profiles, :only => [:index, :show]
  before_filter :load_hardware_profile, :only => [:show]
  before_filter :setup_new_hardware_profile, :only => [:new]
  before_filter :setup_hardware_profile, :only => [:new, :create, :edit, :update]

  def index
    @params = params
    @search_term = params[:q]
    if @search_term.blank?
      load_hardware_profiles
      return
    end

    search = HardwareProfile.search do
      keywords(params[:q])
      with(:frontend, true)
    end
    @hardware_profiles = search.results
  end

  def show
    @hardware_profile = HardwareProfile.find(params[:id].to_a.first)
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
    build_hardware_profile(params[:hardware_profile])
    if params[:commit] == 'Save'
      if @hardware_profile.save!
        redirect_to admin_hardware_profiles_path
      else
        params.delete :commit
        render :action => 'create'
      end
    else
      matching_provider_hardware_profiles
      render :action => 'new'
    end
  end

  def delete
  end

  def edit
    unless @hardware_profile
      @hardware_profile = HardwareProfile.find(params[:id])
    end
    matching_provider_hardware_profiles
  end

  def update
    if params[:commit] == "Reset"
      redirect_to edit_admin_hardware_profile_url(@hardware_profile) and return
    end

    if params[:id]
      @hardware_profile = HardwareProfile.find(params[:id])
      build_hardware_profile(params[:hardware_profile])
    end

    if params[:commit] == "Check Matches"
      matching_provider_hardware_profiles
      render :edit and return
    end

    unless @hardware_profile.save!
      render :action => 'edit' and return
    else
      flash[:notice] = "Hardware Profile updated!"
      redirect_to admin_hardware_profiles_path
    end
  end

  def multi_destroy
    HardwareProfile.destroy(params[:hardware_profile_selected])
    redirect_to admin_hardware_profiles_path
  end

  def matching_profiles
    begin
      hwp = HardwareProfile.find(params[:hardware_profile_id])
      provider = Provider.find(params[:provider_id])
      @hardware_profile = HardwareProfile.match_hwp(hwp, provider)
      if !@hardware_profile.nil?
         render :partial => 'templates/xml/hardware_profile.xml', :locals => { :profile => @hardware_profile }
      else
         head :not_found
      end
    rescue ActiveRecord::RecordNotFound
      head :not_found
    rescue Exception => e
      head :internal_server_error
    end
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
      { :name => "Virtual CPU", :sort_attr => :cpus}
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
    @url_params = params
    @header  = [
      { :name => "Name", :sort_attr => :name},
      { :name => "Unit", :sort_attr => :unit},
      { :name => "Minimum Value", :sort_attr => :value}]
  end

  def set_params_and_header
    @url_params = params
    @header = [
      { :name => "Hardware Profile Name", :sort_attr => :name },
      { :name => "Architecture", :sort_attr => :architecture },
      { :name => "Memory", :sort_attr => :memory},
      { :name => "Storage", :sort_attr => :storage },
      { :name => "Virtual CPU", :sort_attr => :cpus}
    ]
  end

  def load_hardware_profiles
    @hardware_profiles = HardwareProfile.all(:conditions => 'provider_id IS NULL')
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
    hwpp.nil? ? hardwareProfileProperty = HardwareProfileProperty.new : hardwareProfileProperty = hwpp

    hardwareProfileProperty.name = params[:name]
    hardwareProfileProperty.kind = "fixed"
    hardwareProfileProperty.value = params[:value]
    hardwareProfileProperty.unit = params[:unit]
    return hardwareProfileProperty
  end

end
