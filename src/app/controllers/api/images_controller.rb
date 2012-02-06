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

    respond_to :xml
    layout :false

    def index
      if (@environment = params[:environment_id])
        @images = Aeolus::Image::Warehouse::Image.by_environment(@environment)
      else
        @images = Aeolus::Image::Warehouse::Image.all
      end
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
        elsif req[:type] == :failed_env
          raise(Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.specify_environment")))
        elsif req[:type] == :build
          errors = TemplateXML.validate(req[:params][:template])
          raise Aeolus::Conductor::API::ParameterDataIncorrect.new(400, t("api.error_messages.invalid_template", :errors => errors.join(", "))) if errors.any?
          raise Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.environment_required")) if req[:params][:environment].nil?
          @pool_family = PoolFamily.find_by_name(req[:params][:environment])
          raise Aeolus::Conductor::API::ParameterDataIncorrect.new(400, t("api.error_messages.environment_not_found", :environment => req[:params][:environment])) if @pool_family.nil?
          check_permissions
          environment_targets = @pool_family.build_targets

          @targetnotfound=false
          @badtarget=""
          req[:params][:targets].split(",").each do |t|
            target = ProviderType.find_by_deltacloud_driver(t)
            if !target
              @targetnotfound=true
              @badtarget=t
            elsif !environment_targets.include?(t)
              raise(Aeolus::Conductor::API::ParameterDataIncorrect.new(400, t("api.error_messages.target_not_found_in_environment", :target => t, :targets => environment_targets.join(", "))))
            end
          end
          if @targetnotfound
            raise(Aeolus::Conductor::API::TargetNotFound.new(404, t("api.error_messages.target_not_found", :target => @badtarget)))
          end

          uuid = UUIDTools::UUID.timestamp_create.to_s
          @tpl = Aeolus::Image::Warehouse::Template.create!(uuid, req[:params][:template], {
            :object_type => 'template',
            :uuid => uuid
          })
          uuid = UUIDTools::UUID.timestamp_create.to_s
          body = "<image><name>#{@tpl.name}</name></image>"
          iwhd_image = Aeolus::Image::Warehouse::Image.create!(uuid, body, {
            :uuid => uuid,
            :object_type => 'image',
            :template => @tpl.uuid,
            :environment => @pool_family.name
          })
          @image = Aeolus::Image::Factory::Image.new(:id => iwhd_image.id)
          @image.targets = req[:params][:targets]
          @image.template = req[:params][:template]
          @image.save!
          respond_with(@image)
        elsif req[:type] == :import
          account = ProviderAccount.find_by_label(req[:params][:provider_account_name])
          raise(Aeolus::Conductor::API::ProviderAccountNotFound.new(404, t("api.error_messages.provider_account_not_found",
            :name => req[:params][:provider_account_name]))) unless account.present?
          raise Aeolus::Conductor::API::InsufficientParametersSupplied.new(400, t("api.error_messages.environment_required")) if req[:params][:environment].nil?
          @pool_family = PoolFamily.find_by_name(req[:params][:environment])
          raise Aeolus::Conductor::API::ParameterDataIncorrect.new(400, t("api.error_messages.environment_not_found", :environment => req[:params][:environment])) if @pool_family.nil?
          check_permissions
          environment_accounts = @pool_family.provider_accounts
          if !environment_accounts.include?(account)
            raise(Aeolus::Conductor::API::ParameterDataIncorrect.new(400, t("api.error_messages.account_not_found_in_environment", :account => account.label, :accounts => environment_accounts.collect{|a|a.label}.join(", "))))
          end
          begin
            @image = Image.import(account, req[:params][:target_identifier], @pool_family, req[:params][:image_descriptor])
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
          @pool_family = PoolFamily.find_by_name(@image.environment)
          check_permissions
          @provider_images = @image.provider_images
          if @image.delete!
            respond_with(@image, @provider_images)
          end
        else
          raise(Aeolus::Conductor::API::ImageNotFound.new(404, t("api.error_messages.image_not_found", :image => params[:id])))
        end
      rescue Aeolus::Conductor::API::ImageNotFound => e
        raise(e)
      rescue => e
        raise(Aeolus::Conductor::API::ImageDeleteFailure.new(500, e.message))
      end
    end

    private
    def process_post(body)
      doc = Nokogiri::XML CGI.unescapeHTML(body)
      if !doc.xpath("/image/targets").empty? && !doc.xpath("/image/tdl/template").empty? && !doc.xpath("/image/environment").empty?
        { :type => :build, :params => { :template => doc.xpath("/image/tdl/template").to_s,
                                        :targets => doc.xpath("/image/targets").text,
                                        :environment => doc.xpath("/image/environment").text}
        }
      elsif !doc.xpath("/image/provider_account_name").empty? && !doc.xpath("/image/target_identifier").empty? &&
                 !doc.xpath("/image/image_descriptor").empty? && !doc.xpath("/image/environment").empty?

        { :type => :import, :params => { :target_identifier => doc.xpath("/image/target_identifier").text,
                                         :image_descriptor => doc.xpath("/image/image_descriptor").children.first.to_s,
                                         :provider_account_name => doc.xpath("/image/provider_account_name").text,
                                        :environment => doc.xpath("/image/environment").text }
        }
      elsif !doc.xpath("/image").empty? && doc.xpath("/image/environment").empty?
        { :type => :failed_env }
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
