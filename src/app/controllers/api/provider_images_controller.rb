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
    before_filter :require_user

    respond_to :xml
    layout :false

    def index
      @images = Aeolus::Image::Warehouse::ProviderImage.all
      respond_with(@images)
    end

    def show
      id = params[:id]
      @image = Aeolus::Image::Warehouse::ProviderImage.find(id)
      if @image
        respond_with(@image)
      else
        render :nothing => true, :status => 404
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
      rescue
        render :text => "Internal Server Error", :status => 500
      end
    end

    private
    def process_post(body)
      doc = Nokogiri::XML body
      if !doc.xpath("/image/provider_name").empty? && !doc.xpath("/image/provider_account").empty? &&
           !doc.xpath("/image/image_id").empty? && !doc.xpath("/image/build_id").empty? &&
             !doc.xpath("/image/target_image_id").empty?
        if provider_account = ProviderAccount.find_by_label(doc.xpath("/image/provider_account").text)
          #TODO check user permission on this provider account
          { :type => :push, :params => { :provider => doc.xpath("/image/provider_name").text,
                                         :credentials => provider_account.to_xml,
                                         :image_id => doc.xpath("/image/image_id").text,
                                         :build_id => doc.xpath("/image/build_id").text,
                                         :target_image_id => doc.xpath("/image/target_image_id").text } }
        end
      else
        { :type => :failed }
      end
    end
  end
end