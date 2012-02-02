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
      flash[:error] = []
      flash[:error] << t("deployables.flash.error.no_catalog_exists") if @catalogs.empty?
      flash[:error] << t("deployables.flash.error.no_hwp_exists") if @hw_profiles.empty?
      @save_disabled = !(flash[:error].empty?)
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
    @images_hash_details = images != [nil] ? @deployable.get_uuids_hash(images) : nil

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
    @pushed_count = 0
    ProviderAccount.includes(:provider).where('providers.enabled' => true).each do |account|
      type = account.provider.provider_type.deltacloud_driver
      @build_results[type] ||= []
      status = @deployable.build_status(images, account)
      @pushed_count += 1 if (status == :pushed)
      @build_results[type] << {
        :account => account.label,
        :provider => account.provider.name,
        :status => status,
      }
    end

    respond_to do |format|
      format.html
      format.json do
        render :json => { :build_results => @build_results }
      end
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
      raise t("deployables.flash.error.no_catalog") if @selected_catalogs.empty?
      @deployable.transaction do
        @deployable.save!
        @selected_catalogs.each do |catalog|
          require_privilege(Privilege::MODIFY, catalog)
          CatalogEntry.create!(:catalog_id => catalog.id, :deployable_id => @deployable.id)
        end
        flash[:notice] = t("catalog_entries.flash.notice.added", :catalog => @selected_catalogs.map{|c| c.name}.join(", "))
        if params[:edit_xml]
          redirect_to edit_polymorphic_path([@selected_catalogs.first, @deployable], :edit_xml =>true)
        elsif params[:create_from_image]
          redirect_to @deployable
        else
          redirect_to catalog_path(@selected_catalogs.first)
        end
      end
    rescue => e
      flash.now[:warning]= t('deployables.flash.warning.failed', :message => e.message) if @deployable.errors.empty?
      if params[:create_from_image].present?
        load_catalogs
        @image = Aeolus::Image::Warehouse::Image.find(params[:create_from_image])
        @hw_profiles = HardwareProfile.frontend.list_for_user(current_user, Privilege::VIEW)
      else
        @catalog = @selected_catalogs.first
        params.delete(:edit_xml) if params[:edit_xml]
        @form_option = params[:form_option].eql?('upload') ? 'upload' : 'from_url'
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
    deleted = []
    not_deleted = []
    not_deleted_perms = []
    if params[:deployables_selected]
      Deployable.find(params[:deployables_selected]).to_a.each do |d|
        if check_privilege(Privilege::MODIFY, d)
          if d.destroy
            deleted << d.name
          else
            not_deleted << d.name
          end
        else
          not_deleted_perms << d.name
        end
      end
      unless not_deleted.empty? and not_deleted_perms.empty?
        flasherr = []
        flasherr =  t("deployables.flash.error.not_deleted", :count => not_deleted.count, :not_deleted => not_deleted.join(', ')) unless not_deleted.empty?
        flasherr =  t("deployables.flash.error.not_deleted_perms", :count => not_deleted_perms.count, :not_deleted => not_deleted_perms.join(', ')) unless not_deleted_perms.empty?
        flash[:error] = flasherr
      end
      flash[:notice] = t("deployables.flash.notice.deleted", :count => deleted.count, :deleted => deleted.join(', ')) unless deleted.empty?
    else
      flash[:error] = t("deployables.flash.error.not_selected")
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
    require_privilege(Privilege::MODIFY, deployable)
    if deployable.destroy
      flash[:notice] = t("deployables.flash.notice.deleted.one", :deleted => deployable.name)
    else
      flash[:error] = t("deployables.flash.error.not_deleted.one", :not_deleted => deployable.name)
    end

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
      if url.present?
        flash[:error] = t('catalog_entries.flash.warning.not_valid_or_reachable', :url => url)
      else
        flash[:error] = t('catalog_entries.flash.warning.no_url_provided')
      end
      nil
    end
  end
end
