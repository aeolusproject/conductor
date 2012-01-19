#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Api
  class ImagesController < ApplicationController
    before_filter :require_user_api
    before_filter :check_permissions, :only => [:create, :destroy]

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
          errors = TemplateXML.validate(req[:params][:template])
          raise Aeolus::Conductor::API::ParameterDataIncorrect.new(400, t("api.error_messages.invalid_template", :errors => errors.join(", "))) if errors.any?

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
          account = ProviderAccount.find_by_label(req[:params][:provider_account_name])
          raise(Aeolus::Conductor::API::ProviderAccountNotFound.new(404, t("api.error_messages.provider_account_not_found",
            :name => req[:params][:provider_account_name]))) unless account.present?
          begin
            @image = Image.import(account, req[:params][:target_identifier], req[:params][:image_descriptor])
          rescue Aeolus::Conductor::Base::ImageNotFound
            raise(Aeolus::Conductor::API::ImageNotFound.new(404, t("api.error_messages.image_not_found_on_provider",
              :image => req[:params][:target_identifier])))
          end
          respond_with(@image)
        end
      rescue ActiveResource::BadRequest => e
        raise(Aeolus::Conductor::API::ParameterDataIncorrect.new(400, e.message))
      end
    end

    def destroy
      begin
        if @image = Aeolus::Image::Warehouse::Image.find(params[:id])
          @provider_images = @image.provider_images
          if @image.delete!
            respond_with(@image, @provider_images)
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
      elsif !doc.xpath("/image/provider_account_name").empty? && !doc.xpath("/image/target_identifier").empty? &&
                 !doc.xpath("/image/image_descriptor").empty?

        { :type => :import, :params => { :target_identifier => doc.xpath("/image/target_identifier").text,
                                         :image_descriptor => doc.xpath("/image/image_descriptor").children.first.to_s,
                                         :provider_account_name => doc.xpath("/image/provider_account_name").text }
        }
      else
        { :type => :failed }
      end
    end

    def check_permissions
      if check_privilege(Privilege::USE, PoolFamily)
        return true
      else
        raise Aeolus::Conductor::API::PermissionDenied.new(403, t("api.error_messages.insufficient_privileges"))
      end
    end
  end
end
