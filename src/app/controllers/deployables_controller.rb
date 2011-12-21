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
require 'uri'

class DeployablesController < ApplicationController
  before_filter :require_user

  def index
    clear_breadcrumbs
    if params[:catalog_id].present?
      save_breadcrumb(catalog_deployables_path(:viewstate => @viewstate ? @viewstate.id : nil))
      @catalog = Catalog.find(params[:catalog_id])
      @deployables = @catalog.deployables
      @catalog_entries = @deployables.collect { |d| d.catalog_entries.first }
    else
      save_breadcrumb(deployables_path)
      @deployables = Deployable.without_catalog.list_for_user(current_user, Privilege::VIEW)
    end
    set_header
  end

  def new
    @deployable = Deployable.new(params[:deployable])
    require_privilege(Privilege::CREATE, Deployable)
    if params[:create_from_image]
      @image = Aeolus::Image::Warehouse::Image.find(params[:create_from_image])
      @hw_profiles = HardwareProfile.frontend.list_for_user(current_user, Privilege::VIEW)
      @deployable.name = @image.name
      @selected_catalogs = params[:catalog_id].to_a
      load_catalogs
    elsif params[:catalog_id].present?
      @catalog = Catalog.find(params[:catalog_id])
      require_privilege(Privilege::MODIFY, @catalog)
    end
    @form_option= params.has_key?(:from_url) ? 'from_url' : 'upload'
    respond_to do |format|
        format.html
        format.js {render :partial => @form_option}
    end
  end

  def show
    @deployable = Deployable.find(params[:id])
    @catalog = Catalog.find(params[:catalog_id]) if params[:catalog_id].present?
    require_privilege(Privilege::VIEW, @deployable)
    save_breadcrumb(polymorphic_path([@catalog, @deployable]), @deployable.name)
    @providers = Provider.all
    @catalogs_options = Catalog.list_for_user(current_user, Privilege::VIEW).select {|c| !@deployable.catalogs.include?(c)}

    if @catalog.present?
      add_permissions_inline(@deployable, '', {:catalog_id => @catalog.id})
    else
      add_permissions_inline(@deployable)
    end

    @images_details = @deployable.get_image_details
    images = @deployable.fetch_images
    uuids = @deployable.fetch_image_uuids
    @missing_images = images.zip(uuids).select{|p| p.first.nil?}.map{|p| p.second}

    @images_details.each do |assembly|
      assembly.keys.each do |key|
        @deployable_errors ||= []
        @deployable_errors << "#{assembly[:name]}: #{assembly[key]}" if key.to_s =~ /^error\w+/
      end
      if @missing_images.include?(assembly[:image_uuid])
        @deployable_errors << "#{assembly[:name]}: Image (UUID: #{assembly[:image_uuid]}) doesn't exist."
      end
      flash.now[:error] = @deployable_errors unless @deployable_errors.empty?
    end

    return unless @missing_images.empty?

    @build_results = {}
    ProviderAccount.list_for_user(current_user, Privilege::VIEW).includes(:provider).where('providers.enabled' => true).each do |account|
      type = account.provider.provider_type.deltacloud_driver
      @build_results[type] ||= []
      @build_results[type] << {
        :account => account.label,
        :provider => account.provider.name,
        :status => @deployable.build_status(images, account),
      }
    end
  end

  def definition
    @deployable = Deployable.find(params[:id])
    require_privilege(Privilege::VIEW, @deployable)
    render :xml => @deployable.xml
  end

  def create
    if params[:cancel]
      redirect_to polymorphic_path([params[:catalog_id], Deployable])
      return
    end

    require_privilege(Privilege::CREATE, Deployable)
    @deployable = Deployable.new(params[:deployable])
    @selected_catalogs = Catalog.find(params[:catalog_id].to_a)
    @deployable.owner = current_user

    if params.has_key? :url
        xml = import_xml_from_url(params[:url])
        unless xml.nil?
          #store xml_filename for url (i.e. url ends to: foo || foo.xml)
          @deployable.xml_filename =  File.basename(URI.parse(params[:url]).path)
          @deployable.xml = xml
        end
    elsif params[:create_from_image].present?
      hw_profile = HardwareProfile.frontend.find(params[:hardware_profile])
      require_privilege(Privilege::VIEW, hw_profile)
      @deployable.set_from_image(params[:create_from_image], params[:deployable][:name], hw_profile)
    end

    begin
      #raise t("deployables.flash.error.no_catalog") if @selected_catalogs.empty?
      @deployable.transaction do
        @deployable.save!
        @selected_catalogs.each do |catalog|
          require_privilege(Privilege::MODIFY, catalog)
          CatalogEntry.create!(:catalog_id => catalog.id, :deployable_id => @deployable.id)
        end
        flash[:notice] = t "catalog_entries.flash.notice.added"
        if params[:edit_xml]
          redirect_to edit_polymorphic_path([@selected_catalogs.first, @deployable], :edit_xml =>true)
        else
          redirect_to polymorphic_path([@selected_catalogs.first, Deployable])
        end
      end
    rescue => e
      flash[:warning]= t('deployables.flash.warning.failed', :message => e.message)
      flash[:warning]= t('catalog_entries.flash.warning.not_valid') if @deployable.errors.has_key?(:xml)
      if params[:create_from_image].present?
        load_catalogs
        @image = Aeolus::Image::Warehouse::Image.find(params[:create_from_image])
        @hw_profiles = HardwareProfile.frontend.list_for_user(current_user, Privilege::VIEW)
      else
        @catalog = @selected_catalogs.first
        params.delete(:edit_xml) if params[:edit_xml]
        @form_option = params[:deployable].has_key?(:xml) ? 'upload' : 'from_url'
      end
      render :new
    end
  end

  def edit
    @deployable = Deployable.find(params[:id])
    require_privilege(Privilege::MODIFY, @deployable)
    @catalog = Catalog.find(params[:catalog_id]) if params[:catalog_id].present?
  end

  def update
    @deployable = Deployable.find(params[:id])
    @catalog = Catalog.find(params[:catalog_id]) if params[:catalog_id].present?
    require_privilege(Privilege::MODIFY, @deployable)
    params[:deployable].delete(:owner_id) if params[:deployable]

    if @deployable.update_attributes(params[:deployable])
      flash[:notice] = t"catalog_entries.flash.notice.updated"
      redirect_to polymorphic_path([@catalog, @deployable])
    else
      render :action => 'edit', :edit_xml => params[:edit_xml]
    end
  end

  def multi_destroy
    @catalog = nil
    Deployable.find(params[:deployables_selected]).to_a.each do |d|
      # TODO: delete only in catalogs where I have permission to
      #require_privilege(Privilege::MODIFY, d.catalog)
      require_privilege(Privilege::MODIFY, d)
      #@catalog = d.catalog
      d.destroy
    end

    @catalog = Catalog.find(params[:catalog_id]) if params[:catalog_id].present?
    if @catalog.present?
      redirect_to catalog_path(@catalog)
    else
      redirect_to deployables_path
    end
  end

  def destroy
    deployable = Deployable.find(params[:id])
    @catalog = Catalog.find(params[:catalog_id]) if params[:catalog_id].present?
    # TODO: delete only in catalogs where I have permission to
    #require_privilege(Privilege::MODIFY, catalog_entry.catalog)
    require_privilege(Privilege::MODIFY, deployable)
    deployable.destroy

    respond_to do |format|
      format.html do
        if @catalog.present?
          redirect_to catalog_path(@catalog)
        else
          redirect_to deployables_path
        end
      end
    end
  end

  def filter
    redirect_to_original({"catalog_entries_preset_filter" => params[:catalog_entries_preset_filter], "catalog_entries_search" => params[:catalog_entries_search]})
  end

  def build
    catalog = Catalog.find(params[:catalog_id]) if params[:catalog_id].present?
    deployable = Deployable.find(params[:id])
    require_privilege(Privilege::MODIFY, catalog) if catalog.present?
    require_privilege(Privilege::MODIFY, deployable)

    images = deployable.fetch_images
    accounts = ProviderAccount.list_for_user(current_user, Privilege::VIEW)
    options = params[:build_options].to_sym
    case options
    when :build_missing
      deployable.build_missing(images, accounts)
    when :push_missing
      deployable.push_missing(images, accounts)
    end
    redirect_to polymorphic_path([catalog, deployable])
  end

  private

  def set_header
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t("catalog_entries.index.name"), :sort_attr => :name },
      { :name => t("catalogs.index.catalog_name"), :sortable => false },
      { :name => t("catalog_entries.index.deployable_xml"), :sortable => :url }
    ]
  end

  def load_catalogs
    @catalogs = Catalog.list_for_user(current_user, Privilege::MODIFY)
  end

  def import_xml_from_url(url)
    begin
      response = RestClient.get(url, :accept => :xml)
      if response.code == 200
        response
      end
    rescue RestClient::Exception, SocketError, URI::InvalidURIError
      flash[:error] = t('catalog_entries.flash.warning.not_valid_or_reachable', :url => url)
      nil
    end
  end
end
