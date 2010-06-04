require 'yaml'

class ImageDescriptorTarget < ActiveRecord::Base
  belongs_to :image_descriptor

  #TODO: validations
  validates_presence_of :name

  def self.new_if_not_exists(data)
    unless find(:first, :conditions => {:name => data[:name], :image_descriptor_id => data[:image_descriptor_id]})
      ImageDescriptorTarget.new(data).save!
    end
  end

  def self.available_targets
    return YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_targets.yml")
  end
end
