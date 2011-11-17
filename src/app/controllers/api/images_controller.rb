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
      respond_with(@images)
    end

    def show
      id = params[:id]
      @image = Aeolus::Image::Warehouse::Image.find(id)
      if @image
        @builds = @image.image_builds
        respond_with(@image)
      else
        raise(Aeolus::Conductor::API::ImageNotFound.new(404, t("api.error_messages.image_not_found", :image => id)))
      end
    end

    def create
      @errors=[]
      req = process_post(request.body.read)
      begin
        if req[:type] == :failed
          raise(Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.specify_a_type_build_or_import")))
        elsif req[:type] == :build
          @targetnotfound=false
          @badtarget=""
          req[:params][:targets].split(",").each do |t|
            target = ProviderType.find_by_deltacloud_driver(t)
            if !target
              @targetnotfound=true
              @badtarget=t
            end
          end
          if @targetnotfound
            raise(Aeolus::Conductor::API::TargetNotFound.new(404, t("api.error_messages.target_not_found", :target => @badtarget)))
          end
          @image = Aeolus::Image::Factory::Image.new(req[:params])
          @image.save!
          respond_with(@image)
        elsif req[:type] == :import
          @image = Aeolus::Image::Factory::Image.new(req[:params])
          @image.save!
          respond_with(@image)
        end
      rescue ActiveResource::BadRequest => e
        raise(Aeolus::Conductor::API::ParameterDataIncorrect.new(400, e.message))
      end
    end

    def destroy
      begin
        if image = Aeolus::Image::Warehouse::Image.find(params[:id])
          if image.delete!
            render :xml => "<status>Image Deleted</status>", :status => 200
          end
        else
          raise(Aeolus::Conductor::API::ImageNotFound.new(404, t("api.error_messages.image_not_found", :image => params[:id])))
        end
      rescue => e
        raise(Aeolus::Conductor::API::ImageDeleteFailure.new(500, e.message))
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
                                         :targets => doc.xpath("/image/target_name").text,
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
