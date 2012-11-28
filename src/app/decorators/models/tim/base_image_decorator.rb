Tim::BaseImage.class_eval do
  include PermissionedObject

  attr_reader :template_url, :template_file

  belongs_to :pool_family
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"

  validates_presence_of :pool_family_id

  before_create :generate_uuid

  def template_url=(url)
    init_template(import_xml_from_url(url))
  end

  def template_file=(file)
    init_template(file.read)
  end

  def perm_ancestors
    super + [pool_family]
  end

  def imported?
    # TODO: implement this
    false
  end

  def last_built_image_version
    # TODO: returns latest image version for which there is at least one target
    # image (we don't care about build status)
    image_versions.joins(:target_images).order('created_at DESC')
  end

  private

  def init_template(xml)
    self.template = Tim::Template.new(
      :xml         => xml,
      :pool_family => pool_family
    )
  end

  #TODO: DRY this, taken from application controller
  def import_xml_from_url(url)
    if url.blank?
      errors.add(:base, t('application_controller.flash.error.no_url_provided'))
    elsif not url =~ URI::regexp
      errors.add(:base, t('application_controller.flash.error.not_valid_url', :url => url))
    else
      begin
        response = RestClient.get(url, :accept => :xml)
        if response.code == 200
          return response
        else
          errors.add(:base, t('application_controller.flash.error.download_failed'))
        end
      rescue RestClient::Exception, SocketError, URI::InvalidURIError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
        errors.add(:base, t('application_controller.flash.error.not_valid_or_reachable', :url => url))
      end
    end
    return nil
  end

  def generate_uuid
    self[:uuid] = UUIDTools::UUID.timestamp_create.to_s
  end
end
