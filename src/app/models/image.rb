# == Schema Information
# Schema version: 20110223132404
#
# Table name: images
#
#  id               :integer         not null, primary key
#  uuid             :string(255)
#  name             :string(255)     not null
#  build_id         :string(255)
#  uri              :string(255)
#  status           :string(255)
#  template_id      :integer
#  created_at       :datetime
#  updated_at       :datetime
#  provider_type_id :integer         default(100), not null
#

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
  include ImageWarehouseObject

  before_save :generate_uuid

  cattr_reader :per_page
  @@per_page = 15

  belongs_to :template, :counter_cache => true
  has_many :provider_images, :dependent => :destroy
  has_many :providers, :through => :provider_images
  belongs_to :provider_type

  validates_presence_of :name
  validates_length_of :name, :maximum => 1024
  validates_presence_of :status
  validates_presence_of :template_id
  validates_presence_of :provider_type_id

  validates_uniqueness_of :template_id, :scope => :provider_type_id

  SEARCHABLE_COLUMNS = %w(name)

  STATE_QUEUED = 'queued'
  STATE_CREATED = 'created'
  STATE_BUILDING = 'building'
  STATE_COMPLETED = 'completed'
  STATE_CANCELED = 'canceled'
  STATE_FAILED = 'failed'

  ACTIVE_STATES = [ STATE_QUEUED, STATE_CREATED, STATE_BUILDING ]
  INACTIVE_STATES = [STATE_COMPLETED, STATE_FAILED, STATE_CANCELED]

  def generate_uuid
    self.uuid ||= "image-#{self.template_id}-#{Time.now.to_f.to_s}"
  end

  # TODO: for now when build is finished we call upload automatically for all providers
  def after_update
    if self.status_changed? and self.status == STATE_COMPLETED
      # TODO: use after_commit callback in rails 3 - it's better to have it outside
      # update transaction
      begin
        invoke_sync
        upload_to_all_providers_with_account
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n  ")
      end
    end
  end

  def self.create_and_build!(template, provider_type)
    if Image.find_by_template_id_and_provider_type_id(template.id, provider_type.id)
      raise ImageExistsError,  "An attempted build of this template for the target '#{provider_type.name}' already exists"
    end
    # TODO: remove this check when we have UI for pushing images
    if provider_type.providers.empty? or not provider_type.providers.detect {|p| !p.provider_accounts.empty?}
      raise "Error: A valid provider and provider account are required to create and build templates"
    end
    img = Image.create!(
      :name => "#{template.name}/#{provider_type.codename}",
      :provider_type_id => provider_type.id,
      :template_id => template.id,
      :status => Image::STATE_QUEUED
    )
    Delayed::Job.enqueue(BuildJob.new(img.id))
    img
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

    if ProviderImage.find_by_provider_id_and_provider_image_key(account.provider.id, image_id)
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
        :status       => STATE_COMPLETED,
        :provider_type_id => account.provider.provider_type_id,
        :template_id  => template.id
      )
      image.save!

      rep = ProviderImage.new(
        :image_id           => image.id,
        :provider_id        => account.provider.id,
        :provider_image_key => image_id,
        :status             => STATE_COMPLETED
      )
      rep.save!

      template.upload
    end
    image
  end

  private

  def upload_to_all_providers_with_account
    provider_type.providers.each do |p|
      # upload only to providers with account
      unless p.provider_accounts.empty?
        pimg = ProviderImage.create!(
          :image => self,
          :provider => p
        )
        Delayed::Job.enqueue(PushJob.new(pimg.id))
      end
    end
  end

  def self.get_account(providername, username, password)
    unless provider = Provider.find_by_name(providername)
      raise "There is not provider with name '#{providername}'"
    end

    account = ProviderAccount.new(:provider => provider, :username => username, :password => password)

    unless account.valid_credentials?
      raise "Invalid credentials for provider '#{providername}'"
    end

    return account
  end
end
