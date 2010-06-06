require 'yaml'

class ImageDescriptorTarget < ActiveRecord::Base
  belongs_to :image_descriptor

  #TODO: validations
  validates_presence_of :name

  STATE_QUEUED = 'queued'
  STATE_WAITING = 'waiting'
  STATE_BUILDING = 'building'
  STATE_COMPLETE = 'complete'
  STATE_CANCELED = 'canceled'

  ACTIVE_STATES = [ STATE_WAITING, STATE_BUILDING ]

  def self.new_if_not_exists(data)
    unless find(:first, :conditions => {:name => data[:name], :image_descriptor_id => data[:image_descriptor_id]})
      ImageDescriptorTarget.new(data).save!
    end
  end

  def self.available_targets
    return YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_targets.yml")
  end
end
