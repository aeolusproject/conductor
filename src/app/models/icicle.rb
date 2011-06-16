# == Schema Information
# Schema version: 20110616100915
#
# Table name: icicles
#
#  id         :integer         not null, primary key
#  uuid       :string(255)
#  xml        :text
#  created_at :datetime
#  updated_at :datetime
#

class Icicle < ActiveRecord::Base
  include ImageWarehouseObject

  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  def self.create_or_update(uuid)
    icicle = Icicle.find_by_uuid(uuid) || Icicle.new(:uuid => uuid)
    icicle.warehouse_sync
    icicle.log_changes
    icicle.save! if icicle.changed?
    icicle
  end

  def warehouse_sync
    obj = warehouse.bucket('icicles').object(self.uuid)
    self.xml = obj.body
  end
end
