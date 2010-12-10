#
# Copyright (C) 2009 Red Hat, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ImageExistsError < Exception;end

class Image < ActiveRecord::Base
  include SearchFilter

  before_save :generate_uuid

  cattr_reader :per_page
  @@per_page = 15

  belongs_to :template, :counter_cache => true
  has_many :replicated_images, :dependent => :destroy
  has_many :providers, :through => :replicated_images

  validates_presence_of :name
  validates_length_of :name, :maximum => 1024
  validates_presence_of :status
  validates_presence_of :target
  validates_presence_of :template_id

  SEARCHABLE_COLUMNS = %w(name)

  STATE_QUEUED = 'queued'
  STATE_CREATED = 'created'
  STATE_BUILDING = 'building'
  STATE_COMPLETE = 'complete'
  STATE_CANCELED = 'canceled'
  STATE_FAILED = 'failed'

  ACTIVE_STATES = [ STATE_QUEUED, STATE_CREATED, STATE_BUILDING ]
  INACTIVE_STATES = [STATE_COMPLETE, STATE_FAILED, STATE_CANCELED]

  def self.available_targets
    return YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_targets.yml")
  end

  def generate_uuid
    self.uuid ||= "image-#{self.template_id}-#{Time.now.to_f.to_s}"
  end

  def self.build(template, target)
    # FIXME: This will need to be enhanced to handle multiple
    # providers of same type, only one is supported right now
    if Image.find_by_template_id_and_target(template.id, target)
      raise ImageExistsError,  "An attempted build of this template for the target '#{target}' already exists"
    end

    unless provider = Provider.find_by_target_with_account(target)
      raise "There is no provider for '#{target}' type with valid account."
    end

    img = nil
    Image.transaction do
      img = Image.create!(
        :name => "#{template.name}/#{target}",
        :target => target,
        :template_id => template.id,
        :status => Image::STATE_QUEUED
      )
      ReplicatedImage.create!(
        :image_id => img.id,
        :provider_id => provider
      )
    end
    return img
  end

  def self.single_import(providername, username, password, image_id)
    account = Image.get_account(providername, username, password)
    Image.import(account, image_id)
  end

  def self.bulk_import(providername, username, password, images)
    account = Image.get_account(providername, username, password)
    images.each do |image|
      begin
        Image.import(account, image['id'])
        $stderr.puts "imported image with id '#{image['id']}'"
      rescue
        $stderr.puts "failed to import image with id '#{image['id']}'"
      end
    end
  end

  def self.import(account, image_id)
    unless raw_image = account.connect.image(image_id)
      raise "There is no image with '#{image_id}' id"
    end

    if ReplicatedImage.find_by_provider_id_and_provider_image_key(account.provider.id, image_id)
      raise "Image '#{image_id}' is already imported"
    end

    image = nil
    ActiveRecord::Base.transaction do
      template = Template.new(
        :name             => raw_image.name + '_template',
        :summary          => raw_image.description,
        :platform_hash    => {:platform => 'unknown',
                              :version => 'unknown',
                              :architecture => raw_image.architecture},
        :complete         => true,
        :uploaded         => true,
        :imported         => true
      )
      template.save!

      image = Image.new(
        :name         => raw_image.name,
        :status       => 'complete',
        :target       => account.provider.cloud_type,
        :template_id  => template.id
      )
      image.save!

      rep = ReplicatedImage.new(
        :image_id           => image.id,
        :provider_id        => account.provider.id,
        :provider_image_key => image_id,
        :uploaded           => true,
        :registered         => true
      )
      rep.save!

      template.upload
    end
    image
  end

  private

  def self.get_account(providername, username, password)
    unless provider = Provider.find_by_name(providername)
      raise "There is not provider with name '#{providername}'"
    end

    account = CloudAccount.new(:provider => provider, :username => username, :password => password)

    unless account.valid_credentials?
      raise "Invalid credentials for provider '#{providername}'"
    end

    return account
  end
end
