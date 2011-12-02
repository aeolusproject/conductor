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
    save_breadcrumb(catalog_deployables_path(:viewstate => @viewstate ? @viewstate.id : nil))
    @catalog = Catalog.find(params[:catalog_id])
    @deployables = @catalog.deployables
    @catalog_entries = @deployables.collect { |d| d.catalog_entries.first }
    #@catalog_entries = CatalogEntry.list_for_user(current_user, Privilege::VIEW).apply_filters(:preset_filter_id => params[:catalog_entries_preset_filter], :search_filter => params[:catalog_entries_search])
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
    else
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
    @catalog = Catalog.find(params[:catalog_id])
    require_privilege(Privilege::VIEW, @deployable)
    save_breadcrumb(catalog_deployable_path(@catalog, @deployable), @deployable.name)
    @providers = Provider.all
    @catalogs_options = Catalog.all.map {|c| [c.name, c.id] unless c == @catalog}.compact
    add_permissions_inline(@deployable)
    @image_details = @deployable.get_image_details
    @image_details.each do |assembly|
      assembly.keys.each do |key|
        flash[:error] = assembly[key] if key.to_s =~ /^error\w+/
      end
    end
  end

  def create
    if params[:cancel]
      redirect_to catalog_deployables_path
      return
    end

    require_privilege(Privilege::CREATE, Deployable)
    @deployable = Deployable.new(params[:deployable])
    @selected_catalogs = Catalog.find(params[:catalog_id]).to_a
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
      @deployable.set_from_image(params[:create_from_image], hw_profile)
    end

    begin
      raise t("deployables.flash.error.no_catalog") if @selected_catalogs.empty?
      @deployable.transaction do
        @deployable.save!
        @selected_catalogs.each do |catalog|
          require_privilege(Privilege::MODIFY, catalog)
          CatalogEntry.create!(:catalog_id => catalog.id, :deployable_id => @deployable.id)
        end
        flash[:notice] = t "catalog_entries.flash.notice.added"
        if params[:edit_xml]
          redirect_to edit_catalog_deployable_path @selected_catalogs.first, @deployable.id, :edit_xml =>true
        else
          redirect_to catalog_deployables_path(@selected_catalogs.first)
        end
      end
    rescue => e
      flash[:warning]= t('deployables.flash.warning.failed', :message => e.message)
      flash[:warning]= t('catalog_entries.flash.warning.not_valid') if @deployable.errors.has_key?(:xml)
      if params[:create_from_image].present?
        load_catalogs
        @image = Aeolus::Image::Warehouse::Image.find(params[:create_from_image])
        @hw_profiles = HardwareProfile.frontend.list_for_user(current_user, Privilege::VIEW)
        @deployable.name = @image.name
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
    @catalog = Catalog.find(params[:catalog_id])
  end

  def update
    @deployable = Deployable.find(params[:id])
    require_privilege(Privilege::MODIFY, @deployable)
    params[:deployable].delete(:owner_id) if params[:deployable]

    if @deployable.update_attributes(params[:deployable])
      flash[:notice] = t"catalog_entries.flash.notice.updated"
      redirect_to catalog_deployable_path(params[:catalog_id], @deployable)
    else
      render :action => 'edit'
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
    redirect_to catalog_path(params[:catalog_id])
  end

  def destroy
    deployable = Deployable.find(params[:id])
    # TODO: delete only in catalogs where I have permission to
    #require_privilege(Privilege::MODIFY, catalog_entry.catalog)
    require_privilege(Privilege::MODIFY, deployable)
    deployable.destroy

    respond_to do |format|
      format.html { redirect_to catalog_path(params[:catalog_id]) }
    end
  end

  def filter
    original_path = Rails.application.routes.recognize_path(params[:current_path])
    original_params = Rack::Utils.parse_nested_query(URI.parse(params[:current_path]).query)
    redirect_to original_path.merge(original_params).merge("catalog_entries_preset_filter" => params[:catalog_entries_preset_filter], "catalog_entries_search" => params[:catalog_entries_search])
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
