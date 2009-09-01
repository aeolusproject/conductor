class Flavor < ActiveRecord::Base
  has_many :instances
  belongs_to :provider

  validates_presence_of :provider_id

  validates_presence_of :external_key
  validates_uniqueness_of :external_key, :scope => :provider_id

  validates_presence_of :name

  validates_presence_of :storage
  validates_numericality_of :storage
  validates_presence_of :memory
  validates_numericality_of :memory

  validates_presence_of :architecture
end
