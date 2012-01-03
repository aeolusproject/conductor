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

class ImagesController < ApplicationController
  before_filter :require_user
  require "lib/image"

  def index
    set_admin_environments_tabs 'images'
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t('images.index.name'), :sort_attr => :name },
      { :name => t('images.index.os'), :sort_attr => :name },
      { :name => t('images.index.os_version'), :sort_attr => :name },
      { :name => t('images.index.architecture'), :sort_attr => :name },
      { :name => t('images.index.last_rebuild'), :sortable => false },
    ]
    @images = Aeolus::Image::Warehouse::Image.all
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def show
    @image = Aeolus::Image::Warehouse::Image.find(params[:id])
    if @image.imported?
      begin
        # For an imported image, we only want to show the actual provider account
        # This can raise exceptions with old/bad data, though, so rescue and show all providers
        pimg =  @image.provider_images.first
        provider = Provider.find_by_name(pimg.provider)
        type = provider.provider_type
        acct = ProviderAccount.enabled.find_by_provider_name_and_login(provider.name, pimg.provider_account_identifier)
        raise unless acct
        @account_groups = {type.deltacloud_driver => {:type => type, :accounts => [acct]}}
      rescue Exception => e
        @account_groups = ProviderAccount.enabled.group_by_type(current_user)
      end
    else
      @account_groups = ProviderAccount.enabled.group_by_type(current_user)
    end
    # according to imagefactory Builder.first shouldn't be implemented yet
    # but it does what we need - returns builder object which contains
    # all builds
    @builder = Aeolus::Image::Factory::Builder.first
    load_builds
    load_target_images(@build)
  end

  def rebuild_all
    @image = Aeolus::Image::Warehouse::Image.find(params[:id])
    factory_image = Aeolus::Image::Factory::Image.new(:id => @image.id)
    factory_image.targets = Provider.list_for_user(current_user, Privilege::VIEW).map {|p| p.provider_type.deltacloud_driver}.uniq.join(',')
    factory_image.template = @image.template_xml.to_s
    factory_image.save!
    redirect_to image_path(@image.id)
  end

  def template
    image = Aeolus::Image::Warehouse::Image.find(params[:id])
    template = Aeolus::Image::Warehouse::Template.find(image.template)
    if template
      render :xml => template.body
    else
      flash[:error] = t('images.flash.error.no_template')
      redirect_to image_path(@image)
    end
  end

  def new
    if 'import' == params[:tab]
      @accounts = ProviderAccount.enabled.list_for_user(current_user, Privilege::USE)
      render :import and return
    else
      @environment = PoolFamily.find(params[:environment])
    end

  end

  def import
    account = ProviderAccount.find(params[:provider_account])
    xml = "<image><name>#{params[:name]}</name></image>" unless params[:name].blank?
    begin
      image = Image.import(account, params[:image_id], xml)
      flash[:success] = t("images.import.image_imported")
      redirect_to image_url(image.id) and return
    rescue Exception => e
      logger.error "Caught exception importing image: #{e.message}"
      if e.is_a?(Aeolus::Conductor::Base::ImageNotFound)
        flash[:error] = t('images.not_on_provider')
      elsif e.is_a?(Aeolus::Conductor::Base::BlankImageId)
        flash[:error] = t('images.import.blank_id')
      else
        flash[:error] = t("images.import.image_not_imported")
      end
      redirect_to new_image_url(:tab => 'import')
    end
  end

  def edit_xml
    @environment = PoolFamily.find(params[:environment])
    @name = params[:name]

    if params.has_key? :image_url
      url = params[:image_url]
      begin
        xml_source = RestClient.get(url, :accept => :xml)
      rescue RestClient::Exception, SocketError, URI::InvalidURIError, Errno::ECONNREFUSED
        flash.now[:error] = t('images.flash.error.invalid_url')
        render :new and return
      end
    else
      file = params[:image_file]
      xml_source = file && file.read
      unless xml_source
        flash.now[:error] = t('images.flash.error.no_file')
        render :new and return
      end
    end

    begin
      doc = TemplateXML.new(xml_source)
    rescue Nokogiri::XML::SyntaxError
      errors = [t('template_xml.errors.xml_parse_error')]
    else
      doc.name = @name unless @name.blank?
      @name = doc.name
      @xml = doc.to_xml
      errors = doc.validate
    end

    if errors.any?
      flash.now[:error] = errors
      @xml = xml_source
      render :edit_xml and return
    end
    render :overview unless params[:edit]
  end

  def overview
    @environment = PoolFamily.find(params[:environment])
    @name = params[:name]
    @xml = params[:image_xml]

    doc = TemplateXML.new(@xml)
    errors = doc.validate
    if errors.any?
      flash.now[:error] = errors
      render :edit_xml and return
    else
      @name = doc.name
    end
  end

  def create
    @environment = PoolFamily.find(params[:environment])
    @name = params[:name]
    @xml = params[:image_xml]

    if params.has_key? :back
      render :edit_xml and return
    end

    errors = TemplateXML.validate(@xml)
    if errors.any?
      flash.now[:error] = errors
      render :edit_xml and return
    end

    uuid = UUIDTools::UUID.timestamp_create.to_s
    @template = Aeolus::Image::Warehouse::Template.create!(uuid, @xml, {
      :object_type => 'template',
      :uuid => uuid
    })
    uuid = UUIDTools::UUID.timestamp_create.to_s
    body = "<image><name>#{@template.name}</name></image>"
    @image = Aeolus::Image::Warehouse::Image.create!(uuid, body, {
      :uuid => uuid,
      :object_type => 'image',
      :template => @template.uuid
    })
    flash.now[:error] = t('images.flash.notice.created')
    if params[:make_deployable]
      redirect_to new_deployable_path(:create_from_image => @image.id)
    else
      redirect_to image_path(@image.id)
    end
  end

  def edit
  end

  def update
  end

  def destroy
    if image = Aeolus::Image::Warehouse::Image.find(params[:id])
      if image.delete!
        flash[:notice] = t('images.flash.notice.deleted')
      else
        flash[:warning] = t('images.flash.warning.delete_failed')
      end
    else
      flash[:warning] = t('images.flash.warning.not_found')
    end
    redirect_to images_path
  end

  def multi_destroy
    selected_images = params[:images_selected].to_a
    selected_images.each do |uuid|
      image = Aeolus::Image::Warehouse::Image.find(uuid)
      image.delete!
    end
    redirect_to images_path, :notice => t("images.flash.notice.multiple_deleted", :count => selected_images.count)
  end

  protected
  def load_target_images(build)
    @target_images_by_target = {}
    return unless build
    build.target_images.each {|timg| @target_images_by_target[timg.target] = timg}
    @target_images_by_target
  end

  def load_builds
    @builds = @image.image_builds.sort {|a, b| a.timestamp <=> b.timestamp}.reverse
    @latest_build = @image.latest_pushed_or_unpushed_build.uuid rescue nil
    @build = if params[:build].present?
               @builds.find {|b| b.id == params[:build]}
             elsif @latest_build
               @builds.find {|b| b.id == @latest_build}
             else
               @builds.first
             end
  end
end
