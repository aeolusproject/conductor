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

  def index
    set_admin_environments_tabs 'images'
    @header = [
      { :name => t('images.index.name'), :sort_attr => :name },
      { :name => t('images.environment_header'), :sort_attr => :name },
      { :name => t('images.index.os'), :sort_attr => :name },
      { :name => t('images.index.os_version'), :sort_attr => :name },
      { :name => t('images.index.architecture'), :sort_attr => :name },
      { :name => t('images.index.last_rebuild'), :sortable => false },
    ]
    @images = paginate_collection(Aeolus::Image::Warehouse::Image.all, params[:page], PER_PAGE)
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def show
    @image = Aeolus::Image::Warehouse::Image.find(params[:id])
    @environment = PoolFamily.where('name' => @image.environment).first
    @push_started = params[:push_started] == 'true'
    @pushed_provider_account = ProviderAccount.find(params[:provider_account_id]) if params[:provider_account_id].present?

    if @image.imported?
      begin
        # For an imported image, we only want to show the actual provider account
        # This can raise exceptions with old/bad data, though, so rescue and show all providers
        pimg =  @image.provider_images.first
        provider = Provider.find_by_name(pimg.provider)
        type = provider.provider_type
        acct = ProviderAccount.enabled.find_by_provider_name_and_login(provider.name, pimg.provider_account_identifier)
        raise unless acct
        @account_groups = {type.deltacloud_driver => {:type => type, :accounts => [{:account => acct,:included => @environment.provider_accounts.include?(acct)}]}}
      rescue Exception => e
        @account_groups = ProviderAccount.enabled.group_by_type(@environment)
      end
    else
      @account_groups = ProviderAccount.enabled.group_by_type(@environment)
    end

    # according to imagefactory Builder.first shouldn't be implemented yet
    # but it does what we need - returns builder object which contains
    # all builds
    @builder = Aeolus::Image::Factory::Builder.first
    load_builds
    load_target_images(@build)
    @target_image_exists = @target_images_by_target.any?
    @account_groups_listing = @account_groups.select{ |driver, group| group[:included] || @target_images_by_target[driver] || (@build and @builder.find_active_build(@build.id, driver)) }
    flash[:error] = t("images.flash.error.no_provider_accounts") if @account_groups_listing.blank?

    @user_can_build = (@environment && check_privilege(Privilege::USE, @environment))
    @is_latest_build = (@build && @build.id == @latest_build_id)

    @account_groups_listing = []
    @account_groups.each do |driver, group|
      if group[:included] || @target_images_by_target[driver] || (@build && @builder.find_active_build(@build.id, driver))
        @account_groups_listing << { :provider_type => group[:type], :accounts => group[:accounts].map{ |account| account[:account] if account[:included] }.compact }
      end
    end
    flash[:error] = t("images.flash.error.no_provider_accounts") if @account_groups_listing.empty?

    @images_by_provider_type = []
    @account_groups_listing.each do |account_group|
      provider_type = account_group[:provider_type]
      target_image = @target_images_by_target[provider_type.deltacloud_driver]
      @images_by_provider_type << load_build_status_for_target_image(account_group, target_image)
    end

    @push_all_enabled = (@build && @build.id == @latest_build_id && @target_image_exists)

    respond_to do |format|
      format.html
      format.json do
        render :json => { :images => @images_by_provider_type, :push_all_enabled => @push_all_enabled,
                          :push_all_path => @push_all_enabled ? push_all_image_path(@image.id, :build_id => @build.id) : nil }
      end
    end
  end

  def rebuild_all
    @image = Aeolus::Image::Warehouse::Image.find(params[:id])
    @environment = PoolFamily.where('name' => @image.environment).first
    check_permissions
    targets = @environment.build_targets
    unless targets.empty?
      factory_image = Aeolus::Image::Factory::Image.new(:id => @image.id)
      factory_image.targets = targets.join(',')
      factory_image.template = @image.template_xml.to_s
      factory_image.save!
    end
    redirect_to image_path(@image.id)
  end

  def push_all
    @image = Aeolus::Image::Warehouse::Image.find(params[:id])
    @environment = PoolFamily.where('name' => @image.environment).first
    check_permissions
    @build = Aeolus::Image::Warehouse::ImageBuild.find(params[:build_id])
    # only latest builds can be pushed
    unless latest_build?(@build)
      redirect_to image_path(@image.id)
      return
    end
    accounts = @environment.provider_accounts
    target_images = @build.target_images
    accounts.each do |account|
      if account.image_status(@image) == :not_pushed
        target = account.provider.provider_type.deltacloud_driver
        target_image = target_images.find { |ti| ti.target == target }
        provider_image = Aeolus::Image::Factory::ProviderImage.new(
          :provider => account.provider.name,
          :credentials => account.to_xml(:with_credentials => true),
          :image_id => @image.uuid,
          :build_id => @build.uuid,
          :target_image_id => target_image.uuid
        )
        provider_image.save!
      end
    end
    redirect_to image_path(@image.id)
  end

  def template
    image = Aeolus::Image::Warehouse::Image.find(params[:id])
    @environment = PoolFamily.where('name' => image.environment).first
    check_permissions
    template = Aeolus::Image::Warehouse::Template.find(image.template)
    if template
      render :xml => template.body
    else
      flash[:error] = t('images.flash.error.no_template')
      redirect_to image_path(@image)
    end
  end

  def new
    @environment = PoolFamily.find(params[:environment])
    check_permissions
    if 'import' == params[:tab]
      @accounts = @environment.provider_accounts.enabled.list_for_user(current_user, Privilege::USE)
      if !@accounts.any?
        flash[:error] = t("images.flash.error.no_provider_accounts_for_import")
      end
      render :import and return
    end

  end

  def import
    account = ProviderAccount.find(params[:provider_account])
    @environment = PoolFamily.find(params[:environment])
    check_permissions

    xml = "<image><name>#{params[:name]}</name></image>" unless params[:name].blank?
    begin
      image = Image.import(account, params[:image_id], @environment, xml)
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
      redirect_to new_image_url(:tab => 'import', :environment => @environment)
    end
  end

  def edit_xml
    @environment = PoolFamily.find(params[:environment])
    check_permissions
    @name = params[:name]

    if params.has_key? :image_url
      url = params[:image_url]
      begin
        xml_source = RestClient.get(url, :accept => :xml)
      rescue RestClient::Exception, SocketError, URI::InvalidURIError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
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
    check_permissions
    @name = params[:name]
    @xml = params[:image_xml]

    begin
      doc = TemplateXML.new(@xml)
    rescue Nokogiri::XML::SyntaxError
      errors = [t('template_xml.errors.xml_parse_error')]
    else
      @name = doc.name
      errors = doc.validate
    end

    if errors.any?
      flash.now[:error] = errors
      render :edit_xml and return
    end
  end

  def create
    @environment = PoolFamily.find(params[:environment])
    check_permissions
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
    @tpl = Aeolus::Image::Warehouse::Template.create!(uuid, @xml, {
      :object_type => 'template',
      :uuid => uuid
    })
    uuid = UUIDTools::UUID.timestamp_create.to_s
    body = "<image><name>#{@tpl.name}</name></image>"
    @image = Aeolus::Image::Warehouse::Image.create!(uuid, body, {
      :uuid => uuid,
      :object_type => 'image',
      :template => @tpl.uuid,
      :environment => @environment.name
    })
    flash.now[:error] = t('images.flash.notice.created')
    redirect_to image_path(@image.id)
  end

  def edit
    check_permissions
  end

  def update
    check_permissions
  end

  def destroy
    if image = Aeolus::Image::Warehouse::Image.find(params[:id])
      @environment = PoolFamily.where('name' => image.environment).first
      check_permissions
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
    selected_images = Array(params[:images_selected])
    selected_images.each do |uuid|
      image = Aeolus::Image::Warehouse::Image.find(uuid)
      @environment = PoolFamily.where('name' => image.environment).first
      check_permissions
      image.delete!
    end
    redirect_to images_path, :notice => t("images.flash.notice.multiple_deleted", :count => selected_images.count)
  end

  protected
  def load_target_images(build)
    @target_images_by_target = {}
    return unless build and @latest_build_id.present?
    build.target_images.each {|timg| @target_images_by_target[timg.target] = timg}
    @target_images_by_target
  end

  def load_builds
    @builds = @image.image_builds.sort {|a, b| a.timestamp <=> b.timestamp}.reverse
    @latest_build_id = @builds.first.uuid if @builds.any?
    @build = if params[:build].present?
               @builds.find {|b| b.id == params[:build]}
             elsif @latest_build_id
               @builds.find {|b| b.id == @latest_build_id}
             else
               nil
             end
  end

  # For now, Image permissions hijack the previously-unused PoolFamily USE privilege
  def check_permissions
    require_privilege(Privilege::USE, @environment)
  end

  def latest_build?(build)
    unless build
      flash[:error] = t('images.show.missing_build')
      return false
    end
    begin
      latest_build = @image.latest_pushed_or_unpushed_build.uuid
      if latest_build != build.id
        flash[:error] = t('images.show.only_latest_builds_can_be_pushed')
        return false
      end
    rescue
      flash[:error] = t('images.show.not_built')
      return false
    end
    return true
  end

  def load_build_status_for_target_image(account_group, target_image)
    provider_type = account_group[:provider_type]
    provider_images_by_provider_account = []

    account_group[:accounts].each do |account|
      provider_images_by_provider_account << load_provider_images(account, target_image)
    end

    active_build = @builder.find_active_build(@build.id, provider_type.deltacloud_driver)
    build_status = { :is_active_build => active_build.present?,
                     :build_action_available => !target_image.present? && (@is_latest_build || !@build),
                     :delete_action_available => target_image.present? }
    build_status[:active_build_status] = active_build.status.capitalize if active_build.present?
    build_status[:build_action_available] &= @user_can_build
    build_status[:delete_action_available] &= @user_can_build

    target_image_for_provider_type = {
      :provider_type => provider_type,
      :build_status => build_status,
      :accounts => provider_images_by_provider_account
    }

    if build_status[:build_action_available]
      target_image_for_provider_type[:build_target_image_path] = image_target_images_path(@image.id, :target => provider_type.deltacloud_driver,
                                                                                          :build_id => @build ? @build.id : nil)
      failed_build_count = @builder.failed_build_count(@build.id, provider_type.deltacloud_driver)
      build_status[:translated_failed_build_count] = t('images.show.failed_build_attempts', :count => failed_build_count) if failed_build_count > 0
    end

    target_image_for_provider_type[:delete_target_image_path] = image_target_image_path(@image.id, target_image.id) if build_status[:delete_action_available]

    target_image_for_provider_type
  end

  def load_provider_images(account, target_image)
    provider_image = target_image.find_provider_image_by_provider_and_account(account.provider.name, account.credentials_hash['username']).first if target_image.present?
    provider_image_details = { :uuid => provider_image.uuid, :target_identifier => provider_image.target_identifier } if provider_image.present?

    push_started_for_account = (@push_started && @pushed_provider_account == account)
    active_push = @builder.find_active_push(target_image.id, account.provider.name, account.credentials_hash['username']) if target_image.present?
    push_status = { :is_active_push =>  active_push.present?,
                    :push_started_for_account => push_started_for_account,
                    :build_action_available => target_image.present? && !provider_image.present? && @is_latest_build && !push_started_for_account,
                    :delete_action_available => provider_image.present? && !@image.imported? }
    push_status[:active_push_status] = active_push.status.capitalize if active_push.present?
    push_status[:build_action_available] &= @user_can_build
    push_status[:delete_action_available] &= @user_can_build

    provider_image_for_provider_account = {
      :account => { :name => account.name, :provider_name => account.provider.name },
      :provider_image => provider_image_details,
      :push_status => push_status
    }

    if push_status[:build_action_available]
      provider_image_for_provider_account[:push_provider_image_path] = image_provider_images_path(@image.id, :build_id => @build.id,
                                                                                                  :target_image_id => target_image.id,
                                                                                                  :account_id => account.id)

      failed_push_count = @builder.failed_push_count(target_image.id, account.provider.name, account.credentials_hash['username'])
      push_status[:translated_failed_push_count] = t('images.show.failed_push_attempts', :count => failed_push_count) if failed_push_count > 0
    end

    provider_image_for_provider_account[:delete_provider_image_path] = image_provider_image_path(@image.id, provider_image.id) if push_status[:delete_action_available]

    provider_image_for_provider_account
  end

end
