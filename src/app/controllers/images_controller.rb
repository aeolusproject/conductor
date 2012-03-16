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

    respond_to do |format|
      format.html
      format.json do
        active_builds = @account_groups.keys.inject({})  do |result, driver|
          result[driver] = @builder.find_active_build(@build.id, driver) if @build
          result[driver].attributes['status'].capitalize! if result[driver]

          result
        end

        active_builds_by_image_id = @account_groups.keys.inject(Hash.new({}))  do |result, driver|
          result[@image.id] = {} unless result.has_key?(@image.id)
          result[@image.id][driver] = @builder.find_active_build_by_imageid(@image.id, driver)
          result[@image.id][driver].attributes['status'].capitalize! if result[@image.id][driver]

          result
        end

        active_pushes = @account_groups.inject({})  do |result, (driver, group)|
          timg = @target_images_by_target[driver]
          group[:accounts].each do |account|
            result[account[:account].id] = @builder.find_active_push(timg.id, account[:account].provider.name, account[:account].credentials_hash['username'])
            result[account[:account].id].attributes['status'].capitalize! if result[account[:account].id]
          end if timg.present?

          result
        end

        provider_images = @account_groups.inject({})  do |result, (driver, group)|
          timg = @target_images_by_target[driver]
          group[:accounts].each do |account|
            result[account[:account].id] = timg.find_provider_image_by_provider_and_account(account[:account].provider.name, account[:account].credentials_hash['username']).first
          end if timg.present?

          result
        end

        failed_build_counts = @account_groups.keys.inject({})  do |result, driver|
          result[driver] = @builder.failed_build_count(@build.id, driver) if @build
          result
        end

        failed_push_counts = @account_groups.inject({})  do |result, (driver, group)|
          timg = @target_images_by_target[driver]
          group[:accounts].each do |account|
            result[account[:account].id] = @builder.failed_push_count(timg.id, account[:account].provider.name, account[:account].credentials_hash['username'])
          end if timg.present?

          result
        end

        render :json => { :image => @image,
                          :build => @build,
                          :account_groups => @account_groups,
                          :provider_images => provider_images,
                          :target_images_by_target => @target_images_by_target,
                          :active_builds => active_builds,
                          :active_builds_by_image_id => active_builds_by_image_id,
                          :active_pushes => active_pushes,
                          :failed_build_counts => failed_build_counts,
                          :failed_push_counts => failed_push_counts,
                          :latest_build_id => @latest_build,
                          :user_can_build => (@environment and
                                              check_privilege(Privilege::USE, @environment)),
                          :target_image_exists => @target_image_exists }
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
    return unless build and @latest_build.present?
    build.target_images.each {|timg| @target_images_by_target[timg.target] = timg}
    @target_images_by_target
  end

  def load_builds
    @builds = @image.image_builds.sort {|a, b| a.timestamp <=> b.timestamp}.reverse
    @latest_build = @builds.first.uuid if @builds.any?
    @build = if params[:build].present?
               @builds.find {|b| b.id == params[:build]}
             elsif @latest_build
               @builds.find {|b| b.id == @latest_build}
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
end
