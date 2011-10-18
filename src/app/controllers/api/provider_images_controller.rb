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
      req = process_post(request.body.read)
      begin
        if req[:type] == :failed
          render :text => "Insufficient Parameters supplied", :status => 400
        else
          @provider_image = Aeolus::Image::Factory::ProviderImage.new(req[:params])
          @provider_image.save!
          respond_with(@provider_image)
        end
      rescue ActiveResource::BadRequest
        render :text => "Parameter Data Incorrect", :status => 400
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

    private
    def process_post(body)
      doc = Nokogiri::XML CGI.unescapeHTML(body)
      puts Nokogiri::XML CGI.unescapeHTML(body)
      if !doc.xpath("/provider_image/provider_name").empty? && !doc.xpath("/provider_image/provider_account").empty? &&
           !doc.xpath("/provider_image/image_id").empty? && !doc.xpath("/provider_image/build_id").empty? &&
             !doc.xpath("/provider_image/target_image_id").empty?
        if provider_account = ProviderAccount.find_by_label(doc.xpath("/provider_image/provider_account").text)
          #TODO check user permission on this provider account
          { :type => :push, :params => { :provider => doc.xpath("/provider_image/provider_name").text,
                                         :credentials => provider_account.to_xml(:with_credentials => true),
                                         :image_id => doc.xpath("/provider_image/image_id").text,
                                         :build_id => doc.xpath("/provider_image/build_id").text,
                                         :target_image_id => doc.xpath("/provider_image/target_image_id").text } }
        end
      else
        { :type => :failed }
      end
    end
  end
end
