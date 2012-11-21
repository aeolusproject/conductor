Tim::Template.class_eval do
  include PermissionedObject

  belongs_to :pool_family
  has_many :permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "permissions.id ASC"
  has_many :derived_permissions, :as => :permission_object, :dependent => :destroy,
           :include => [:role],
           :order => "derived_permissions.id ASC"

  validates_presence_of :pool_family_id

  def perm_ancestors
    super + [pool_family]
  end
end
