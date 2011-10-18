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
  class ImagesController < ApplicationController
    before_filter :require_user_api

    respond_to :xml
    layout :false

    def index
      @images = Aeolus::Image::Warehouse::Image.all
      # TODO This should be in aeolus-image-rubygem
      @builds = {}
      @images.each do |img|
        @builds.merge!({img.id => Aeolus::Image::Warehouse::ImageBuild.find_all_by_image_uuid(img.id)})
      end
      respond_with(@images)
    end

    def show
      id = params[:id]
      @image = Aeolus::Image::Warehouse::Image.find(id)
      if @image
        @builds = {@image.id => Aeolus::Image::Warehouse::ImageBuild.find_all_by_image_uuid(@image.id)}
        respond_with(@image)
      else
        #render :nothing => true, :status => 404
        render :xml => :not_found, :status => :not_found
      end
    end

    def create
      req = process_post(request.body.read)
      begin
        if req[:type] == :failed
          render :text => "Insufficient Parameters supplied", :status => 400
        else
          @image = Aeolus::Image::Factory::Image.new(req[:params])
          @image.save!
          respond_with(@image)
        end
      rescue ActiveResource::BadRequest
        render :text => "Parameter Data Incorrect", :status => 400
      rescue
         render :text => "Internal Server Error From Factory", :status => 500
      end
    end

    private
    def process_post(body)
      doc = Nokogiri::XML CGI.unescapeHTML(body)
      if !doc.xpath("/image/targets").empty? && !doc.xpath("/image/tdl/template").empty?
        { :type => :build, :params => { :template => doc.xpath("/image/tdl/template").to_s,
                                        :targets => doc.xpath("/image/targets").text }
        }
      elsif !doc.xpath("/image/target_name").empty? && !doc.xpath("/image/target_identifier").empty? &&
                 !doc.xpath("/image/image_descriptor").empty? && !doc.xpath("/image/provider_name").empty?

        { :type => :import, :params => { :target_name => doc.xpath("/image/target_name").text,
                                         :target_identifier => doc.xpath("/image/target_identifier").text,
                                         :image_descriptor => doc.xpath("/image/image_descriptor").children.first.to_s,
                                         :provider_name => doc.xpath("/image/provider_name").text }
        }
      else
        { :type => :failed }
      end
    end
  end
end
