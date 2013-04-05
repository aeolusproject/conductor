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

  before_filter :check_request_size, :only=> :edit_xml
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
    if params[:template_source]
      @base_image.template = set_template(params[:template_source],
                                          @base_image.pool_family_id)
    end

    if !@base_image.valid?
      flash.now[:error] ||= []
      flash.now[:error] += @base_image.errors.full_messages
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
    raise _('The Image you tried to access cannot be found. It may have been deleted.') unless @base_image
    if @base_image.imported?
      flash[:error] = _('Imported image can\'t be built or pushed')
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

  def check_request_size
    if request.headers["CONTENT_LENGTH"].to_i > 31457280
      redirect_to request.referrer, :flash => { :error => _('The provided image template is too large. Please provide an XML template.') }
    end
  end

  def load_permissioned_images
    @base_images = Tim::BaseImage.list_for_user(current_session,
                                                current_user,
                                                Alberich::Privilege::VIEW)
  end

  def check_view_permission
    @base_image = Tim::BaseImage.find(params[:id])
    require_privilege(Alberich::Privilege::VIEW, @base_image)
  end

  def check_modify_permission
    @base_image = Tim::BaseImage.find(params[:id])
    require_privilege(Alberich::Privilege::MODIFY, @base_image)
  end

  def check_create_permission
    @base_image = Tim::BaseImage.new(params[:base_image])
    require_privilege(Alberich::Privilege::CREATE, Tim::BaseImage, @base_image.pool_family)
  end

  def set_tabs_and_headers
    set_admin_environments_tabs 'images'
    @header = [
      { :name => _('Name'), :sort_attr => :name },
      { :name => _('Environment'), :sort_attr => :name },
      { :name => _('OS'), :sort_attr => :name },
      { :name => _('OS Version'), :sort_attr => :name },
      { :name => _('Architecture'), :sort_attr => :name },
      { :name => _('Last Rebuild'), :sortable => false },
    ]
  end

  def set_new_form_variables
    @base_image ||= Tim::BaseImage.new(params[:base_image])
    # FIXME: remove this:
    @base_image.template ||= Tim::Template.new

    @accounts = @base_image.pool_family.provider_accounts.enabled.
      list_for_user(current_session, current_user, Alberich::Privilege::USE)
    if @accounts.empty?
      flash.now[:error] = @base_image.import ?
        _('Images cannot be imported. No Provider Accounts are currently enabled for this Environment.') :
        _('Images cannot be built. There are no enabled Provider Accounts associated with this Environment.')
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

  # This sets up @targets, which is a big hash with information on
  # provider types, provider and target images, etc.
  def set_targets
    # Preload up some data
    all_prov_accts = @base_image.pool_family.provider_accounts.
      list_for_user(current_session, current_user, Alberich::Privilege::USE).
      includes(:provider => :provider_type)
    provider_types = available_provider_types_for_base_image(@base_image)
    target_images = @version ? @version.target_images(:include => :provider_images) : []

    # Run over all provider types
    @targets = provider_types.map do |provider_type|
      target_images_for_type = target_images.select{|ti|
        ti.provider_type_id == provider_type.id}
      get_target_info(target_images_for_type, provider_type, all_prov_accts)
    end
     true
  end

  private

  def get_provider_image_data(provider_image, provider_account, target_image)
    info = {}
    # Show push URL if pimg is missing of failed
    if (provider_image.nil? || provider_image.status == Tim::ProviderImage::STATUS_FAILED) &&
      check_privilege(Alberich::Privilege::MODIFY, @base_image) && target_image && target_image.built?
        info[:pimg_push_url] = tim.provider_images_path(
          :provider_image => {
            :provider_account_id => provider_account.id,
            :target_image_id => target_image.id
          }
        )
    # Otherwise, if it's destroyable and the user has permission, show delete link
    elsif provider_image && provider_image.destroyable? && check_privilege(Alberich::Privilege::MODIFY, @base_image)
      info[:pimg_delete_url] = tim.provider_image_path(provider_image.id)
    # Otherwise, we can neither show a push nor delete URL, so just show status:
    else
      info[:pimg_only_status] = true
    end

    # Let's also keep a counter of failed attempts:
    if provider_image && provider_image.status == Tim::ProviderImage::STATUS_FAILED
      info[:pimg_failed_attempts] = t('tim.base_images.show.failed_push_attempts',
        :count => target_image.provider_images.find_all {|i| i.status == Tim::ProviderImage::STATUS_FAILED}.count)
    end
    info
  end

  def get_target_image_info(target_images, provider_type)
    target_image = target_images.last
    info = {}
    # If there's no target image, or it's failed, show a build URL:
    if (target_image.nil? || target_image.status == Tim::TargetImage::STATUS_FAILED) &&
      check_privilege(Alberich::Privilege::MODIFY, @base_image)
        info[:build_url] = tim.target_images_path(:target_image => {
          :provider_type_id => provider_type.id,
          :image_version_id => @version ? @version.id : nil,
        }, :base_image_id => @version ? nil : @base_image.id)
    # otherwise, if the image is destroyable, show a delete link
    elsif target_image.present? && target_image.destroyable? &&
      check_privilege(Alberich::Privilege::MODIFY, @base_image)
        info[:delete_url] = tim.target_image_path(target_image.id)
    # Otherwise, we can't show either, so just show the status:
    else
      info[:only_status] = true
    end

    # Show a counter for failed builds if needed:
    if target_image && target_image.status == Tim::TargetImage::STATUS_FAILED
      info[:failed_attempts] = t('tim.base_images.show.failed_build_attempts',
        :count => target_images.find_all {|i| i.status == Tim::TargetImage::STATUS_FAILED}.count)
    end
    info
  end

  def get_target_info(target_images, provider_type, all_provider_accounts)
    # use last build - there can be multiple target images with failed status
    target_image = target_images.last
    info = {
      :provider_type => provider_type,
      :target_image => target_image,
      :timg_status => target_image && target_image.human_status,
      :timg_progress => target_image && target_image.progress,
      :provider_accounts => []
    }
    info.merge!(get_target_image_info(target_images, provider_type))
    accounts_for_provider_type(provider_type, all_provider_accounts).each do |prov_acct|
      #next unless target_image # jump out of here if target_image is nil
      pimg = target_image.provider_images.select{|pi| pi.provider_account_id ==
        prov_acct.id}.last if target_image
      pinfo = {
        :provider => prov_acct.provider,
        :provider_account => prov_acct,
        :provider_image => pimg,
        :pimg_status => pimg && pimg.status, # or status_detail ?
        :pimg_progress => pimg && pimg.progress
      }
      # Merge in some URLs (from get_provider_image_data):
      pinfo.merge!(get_provider_image_data(pimg, prov_acct, target_image))
      info[:provider_accounts] << pinfo
    end
    # When it's all done, return info:
    return info
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

  def set_template(source, pool_family_id)
    xml = nil
    xml = case source.class.name
          when 'String'
            downloader = DownloadService.new(source)
            unless content = downloader.download
              flash.now[:error] = [downloader.error]
            end
            content
          when 'ActionDispatch::Http::UploadedFile'
            source.read
          else
            nil
          end
    return unless xml
    Tim::Template.new(:xml => xml, :pool_family_id => pool_family_id)
  end
end
