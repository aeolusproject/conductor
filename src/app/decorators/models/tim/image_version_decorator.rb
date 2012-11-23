Tim::ImageVersion.class_eval do
  before_create :generate_uuid

  private

  def generate_uuid
    self[:uuid] = UUIDTools::UUID.timestamp_create.to_s
  end
end
