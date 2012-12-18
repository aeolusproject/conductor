#
#   Copyright 2012 Red Hat, Inc.
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

Tim::BaseImagesController.class_eval do
  before_filter :require_user

  before_filter :load_permissioned_images, :only => :index
  before_filter :check_view_permission, :only => [:show]
  before_filter :check_modify_permission, :only => [:edit, :update, :destroy, :build_all]
  before_filter :check_create_permission, :only => [:new, :create]

  before_filter :set_tabs_and_headers, :only => [:index]
  before_filter :set_new_form_variables, :only => [:new]
  before_filter :set_image_versions, :only => :show
  before_filter :set_targets, :only => :show

  # FIXME: whole create method is overriden just because of
  # setting flash error and new_form_variables if creation fails
  def create
    @base_image = Tim::BaseImage.new(params[:base_image]) unless defined? @base_image

    if params[:back]
      render :edit_xml
      return
    end

    if @base_image.save
      flash[:notice] = "Successfully created Base Image"
    else
      set_new_form_variables
      # TODO: this is temporary fix until this bug is fixed:
      # https://github.com/aeolus-incubator/tim/issues/69
      # we display errors only for selected fields about which we know these are
      # on the page:
      flash.now[:error] = filtered_errors(@base_image)
    end
    respond_with @base_image
  end

  def edit_xml
    @base_image = Tim::BaseImage.new(params[:base_image])

    #TODO: template fetching sets image.errors
    if @base_image.errors.present? or !@base_image.valid?
      flash.now[:error] = @base_image.errors.full_messages
      # if only error is with template XMl, go to edit_xml page
      if @base_image.errors.count == 1 && @base_image.errors['template.xml'].present?
        @base_image.template ||= Tim::Template.new
        render :edit_xml
      else
        set_new_form_variables
        render :new
      end
      return
    end

    render :overview unless params[:edit]
  end

  def overview
    @base_image = Tim::BaseImage.new(params[:base_image])
    unless @base_image.valid?
      @base_image.template ||= Tim::Template.new
      flash.now[:error] = @base_image.errors.full_messages
      render :edit_xml
      return
    end
  end

  # At this time, this will _only_ do builds, but not a push.
  # This is largely due to the latter relying on callbacks working
  # properly in Conductor.
  def build_all
    raise t('tim.base_images.flash.error.not_exist') unless @base_image
    if @base_image.imported?
      flash[:error] = t('tim.base_images.show.can_not_build_imported_image')
      redirect_to @base_image and return
    end
    @version = @base_image.image_versions.create!
    available_provider_types_for_base_image(@base_image).each do |type|
      @version.target_images.create!({
        :provider_type => type
      })
    end
    redirect_to @base_image
  end

  private

  def load_permissioned_images
    @base_images = Tim::BaseImage.list_for_user(current_session,
                                                current_user,
                                                Privilege::VIEW)
  end

  def check_view_permission
    @base_image = Tim::BaseImage.find(params[:id])
    require_privilege(Privilege::VIEW, @base_image)
  end

  def check_modify_permission
    @base_image = Tim::BaseImage.find(params[:id])
    require_privilege(Privilege::MODIFY, @base_image)
  end

  def check_create_permission
    @base_image = Tim::BaseImage.new(params[:base_image])
    require_privilege(Privilege::CREATE, Tim::BaseImage, @base_image.pool_family)
  end

  def set_tabs_and_headers
    set_admin_environments_tabs 'images'
    @header = [
      { :name => t('tim.base_images.index.name'), :sort_attr => :name },
      { :name => t('tim.base_images.environment_header'), :sort_attr => :name },
      { :name => t('tim.base_images.index.os'), :sort_attr => :name },
      { :name => t('tim.base_images.index.os_version'), :sort_attr => :name },
      { :name => t('tim.base_images.index.architecture'), :sort_attr => :name },
      { :name => t('tim.base_images.index.last_rebuild'), :sortable => false },
    ]
  end

  def set_new_form_variables
    @base_image ||= Tim::BaseImage.new(params[:base_image])
    # FIXME: remove this:
    @base_image.template ||= Tim::Template.new

    @accounts = @base_image.pool_family.provider_accounts.enabled.
      list_for_user(current_session, current_user, Privilege::USE)
    if @accounts.empty?
      flash.now[:error] = @base_image.import ?
        t("tim.base_images.flash.error.no_provider_accounts_for_import") :
        t("tim.base_images.flash.error.no_provider_accounts")
    end

    if @base_image.import and @base_image.image_versions.empty?
      @base_image.image_versions = [Tim::ImageVersion.new(
        :target_images => [Tim::TargetImage.new(
          :provider_images => [Tim::ProviderImage.new]
        )]
      )]
    end
  end

  def set_image_versions
    @versions = @base_image.image_versions.order('created_at DESC')
    @latest_version = @versions.first # because we sorted above
    # @version is the specific image version we're viewing
    @version = if params[:build]
      @versions.find{|v| v.uuid == params[:build]} || @latest_version
    else
      @latest_version
    end
  end

  def set_targets
    return [] unless @version # Otherwise, there's no point

    # Preload up some data
    all_prov_accts = @base_image.pool_family.provider_accounts.
      list_for_user(current_session, current_user, Privilege::USE).
      includes(:provider => :provider_type)
    provider_types = available_provider_types_for_base_image(@base_image)
    target_images = @version.target_images(:include => :provider_images)

    # Run over all provider types
    @targets = provider_types.map do |provider_type|
      target_images_for_type = target_images.select{|ti|
        ti.provider_type_id == provider_type.id}
      get_target_info(target_images_for_type, provider_type, all_prov_accts)
    end
  end

  private

  def get_provider_image_data(provider_images, provider_account, target_image)
    # use last push - there can be multiple provider images with failed status
    provider_image = provider_images.last
    provider_image_data = {
      :provider_account => provider_account,
      :provider => provider_account.provider,
      :provider_image => provider_image,
      :status => provider_image && provider_image.status,
      :pimg_progress => provider_image && provider_image.progress,
    }

    if (provider_image.nil? || provider_image.status == Tim::ProviderImage::STATUS_FAILED) &&
      check_privilege(Privilege::MODIFY, @base_image) && target_image &&
      target_image.built?

        provider_image_data[:pimg_push_url] = tim.provider_images_path(
          :provider_image => {
            :provider_account_id => provider_account.id,
            :target_image_id => target_image.id
          }
        )
    elsif provider_image && provider_image.destroyable? &&
      check_privilege(Privilege::MODIFY, @base_image)

        provider_image_data[:pimg_delete_url] = tim.provider_image_path(provider_image.id)
    else
      provider_image_data[:pimg_only_status] = true
    end

    if provider_image && provider_image.status == Tim::ProviderImage::STATUS_FAILED
      provider_image_data[:pimg_failed_attempts] = t('tim.base_images.show.failed_push_attempts',
                                 :count => provider_images.find_all {|i|
                                   i.status == Tim::ProviderImage::STATUS_FAILED
                                  }.count)
    end

    provider_image_data
  end


  def get_target_info(target_images, provider_type, all_prov_accts)
    # use last build - there can be multiple target images with failed status
    target_image = target_images.last
    info = {
      :provider_type => provider_type,
      :target_image => target_image,
      :provider_images => [],
      :status => target_image && target_image.human_status,
      :progress => target_image && target_image.progress,
    }

    if (target_image.nil? || target_image.status == Tim::TargetImage::STATUS_FAILED) &&
      check_privilege(Privilege::MODIFY, @base_image)

        info[:build_url] = tim.target_images_path(:target_image => {
          :provider_type_id => provider_type.id,
          :image_version_id => @version.id
        })
    elsif target_image.present? && target_image.destroyable? &&
      check_privilege(Privilege::MODIFY, @base_image)

        info[:delete_url] = tim.target_image_path(target_image.id)
    else
      info[:only_status] = true
    end

    if target_image && target_image.status == Tim::TargetImage::STATUS_FAILED
      info[:failed_attempts] = t('tim.base_images.show.failed_build_attempts',
                                 :count => target_images.find_all {|i|
                                   i.status == Tim::TargetImage::STATUS_FAILED
                                 }.count)
    end

    provider_accounts = accounts_for_provider_type(provider_type, all_prov_accts)
    provider_accounts.each do |provider_account|
      provider_images = target_image.present? ?
        target_image.provider_images.where(
          :provider_account_id => provider_account.id) : []
      info[:provider_images] << get_provider_image_data(provider_images,
                                                        provider_account,
                                                        target_image)
    end

    info
  end

  # We need this above. For a base image, find all _available_ ProviderTypes,
  # whether or not we have built for it.
  # This was too messy to do above, but feels too arcane to put in the BaseImage model,
  # especially since it's so tangentially related to BaseImages at all.
  def available_provider_types_for_base_image(base_image)
    all_types = []
    # Eager load all the data we'll need, rather than doing a bunch of one-off queries:
    prov_accts = @base_image.pool_family.provider_accounts.includes(:provider => :provider_type)
    prov_accts.each do |provider_account|
      type = provider_account.provider.provider_type
      all_types << type unless all_types.include?(type)
    end
    all_types
  end

  # Another weird one-off with no good home...
  # Find all provider accounts (in a given set, though we could look it up)
  # that have a given provider type.
  def accounts_for_provider_type(provider_type, provider_accounts)
    provider_accounts.select{|pa| pa.provider.provider_type_id == provider_type.id}
  end

  def filtered_errors(obj)
    obj.errors.map do |attr, error|
      next unless [
        :name,
        :base,
        :"image_versions.target_images.provider_images.external_image_id",
        :"image_versions.target_images.provider_type_id"
      ].include?(attr)
      obj.errors.full_message(attr, error)
    end.uniq
  end
end
