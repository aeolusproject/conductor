#
# Copyright (C) 2011 Red Hat, Inc.
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

module Api
  class ProviderImagesController < ApplicationController
    before_filter :require_user_api

    respond_to :xml
    layout :false

    def index
      if params[:target_image_id]
        @images = Aeolus::Image::Warehouse::TargetImage.find(params[:target_image_id]).provider_images
      else
        @images = Aeolus::Image::Warehouse::ProviderImage.all
      end
      respond_with(@images)
    end

    def show
      id = params[:id]
      @image = Aeolus::Image::Warehouse::ProviderImage.find(id)
      if @image
        respond_with(@image)
      else
        status = Aeolus::Image::Factory::ProviderImage.status(id)
        if !status.nil?
          @image = Aeolus::Image::Factory::ProviderImage.new(:id => id,
                                                             :href => api_provider_image_url(id),
                                                             :status => status)
          respond_with(@image)
        else
          render :text => "Resource Not Found", :status => 404
        end
      end
    end

    def create
      doc = Nokogiri::XML CGI.unescapeHTML(request.body.read)
      begin
        target_images = list_target_images(doc)
      rescue ActiveResource::BadRequest => e
        render :text => e.message, :status => 400
        return
      end

      @provider_images = []
      @errors = []
      begin
        doc.xpath("/provider_image/provider_account").text.split(",").each do |account_name|
          if account = ProviderAccount.find_by_label(account_name)
            if target_image = find_target_image_for_account(target_images, account)
              begin
                @provider_images << send_push_request(target_image, account)
              rescue ActiveResource::BadRequest
                @errors << "Invalid Parameters for Account: " + account_name + " TargetImage: " + target_image.id
              rescue => e
                @errors << "Internal Server Error: Could not push TargetImage: " + target_image.id + " to " + account_name
              end
            else
              @errors << "Could not find an appropriate TargetImage for account " + account_name
            end
          else
            @errors << "Could not find Account Named: " + account_name
          end
        end
      rescue => e
        raise e
        render :text => "Internal Server Error", :status => 500
      end
    end

    def destroy
      begin
        if image = Aeolus::Image::Warehouse::ProviderImage.find(params[:id])
          if image.delete!
            render :text => "Provider Image Deleted", :status => 200
          end
        else
          render :text => "Unable to find Provider Image", :status => 404
        end
      rescue => e
        raise e
        render :text => "Unable to Delete Provider Image", :status => 500
      end
    end

    def list_target_images(doc)
      if doc.xpath("/provider_image/provider_account").empty?
        raise(ActiveResource::BadRequest.new("Invalid Parameters: No Provider Account Given"))
      else
        target_images = []
        if !doc.xpath("/provider_image/image_id").empty?
          Aeolus::Image::Warehouse::Image.find(doc.xpath("/provider_image/image_id").text).image_builds.each do |build|
            target_images += build.target_images
          end
          target_images
        elsif !doc.xpath("/provider_image/build_id").empty?
          if build = Aeolus::Image::Warehouse::ImageBuild.find(doc.xpath("/provider_image/build_id").text)
            target_images = build.target_images
          else
            raise(ActiveResource::ResourceNotFound.new("Could not find the specified build"))
          end
        elsif !doc.xpath("/provider_image/target_image_id").empty?
          if target_image = Aeolus::Image::Warehouse::TargetImage.find(doc.xpath("/provider_image/target_image_id").text)
            target_images << target_image
          end
        else
          raise(ActiveResource::BadRequest.new("Invalid Parameters: No Image, Build or TargetImage Provided in Request"))
        end
        if target_images.empty?
          raise(ActiveResource::ResourceNotFound.new("Could not find any matching Target Images"))
        else
          target_images
        end
      end
    end

    def send_push_request(target_image, account)
      provider_image = Aeolus::Image::Factory::ProviderImage.new({:provider => account.provider.name,
                                                                  :credentials => account.to_xml(:with_credentials => true),
                                                                  :image_id => target_image.build.image.id,
                                                                  :build_id => target_image.build.id,
                                                                  :target_image_id => target_image.id })
      provider_image.save!
      provider_image
    end

    def find_target_image_for_account(target_images, account)
      target_images.each do |target_image|
        if target_image.target == account.provider.provider_type.deltacloud_driver
          return target_image
        end
      end
      nil
    end

  end
end
