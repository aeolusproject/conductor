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

class ImagesController < ApplicationController
  before_filter :require_user

  def index
    set_admin_environments_tabs 'images'
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t('images.index.name'), :sort_attr => :name },
      { :name => t('images.index.os'), :sort_attr => :name },
      { :name => t('images.index.os_version'), :sort_attr => :name },
      { :name => t('images.index.architecture'), :sort_attr => :name },
    ]
    @images = Aeolus::Image::Warehouse::Image.all
    respond_to do |format|
      format.html
      format.js { render :partial => 'list' }
    end
  end

  def show
    @image = Aeolus::Image::Warehouse::Image.find(params[:id])
    @builds = @image.image_builds
    @build = if params[:build].present?
               @builds.find {|b| b.id == params[:build]}
             elsif @image.respond_to?(:latest_build) and @image.latest_build
               @builds.find {|b| b.id == @image.latest_build}
             else
               @builds.first
             end
    @provider_types = ProviderType.all
  end

  def new
    @environment = PoolFamily.find(params[:environment])
  end

  def edit_xml
    @environment = PoolFamily.find(params[:environment])
    @name = params[:name]

    if params.has_key? :image_url
      url = params[:image_url]
      begin
        xml_source = RestClient.get(url, :accept => :xml)
      rescue RestClient::Exception, SocketError, URI::InvalidURIError
        flash.now[:error] = t('images.flash.error.invalid_url')
        render :new and return
      end
    else
      file = params[:image_file]
      xml_source = file && file.read
    end

    begin
      doc = Nokogiri::XML(xml_source) { |config| config.strict }
      add_template_name(doc, @name)
      @xml = doc.to_xml
    rescue Nokogiri::XML::SyntaxError
      flash.now[:error] = t('images.flash.warning.invalid_xml')
      @xml = xml_source
      render :edit_xml and return
    end
    render :overview unless params[:edit]
  end

  def overview
    @environment = PoolFamily.find(params[:environment])
    @name = params[:name]
    @xml = params[:image_xml]

    begin
      doc = Nokogiri::XML(@xml) { |config| config.strict }
      xml_name = doc.xpath('/template/name').first
      @name = xml_name.content unless xml_name.blank?
    rescue Nokogiri::XML::SyntaxError
      flash.now[:error] = t('images.flash.warning.invalid_xml')
      render :edit_xml
    end
  end

  def create
    @environment = PoolFamily.find(params[:environment])
    @name = params[:name]
    @xml = params[:image_xml]

    if params.has_key? :back
      render :edit_xml and return
    end

    uuid = UUIDTools::UUID.timestamp_create.to_s
    @template = Aeolus::Image::Warehouse::Template.create!(uuid, @xml, {
      :object_type => 'template',
      :uuid => uuid
    })
    uuid = UUIDTools::UUID.timestamp_create.to_s
    body = "<image><name>#{@template.name}</name></image>"
    @image = Aeolus::Image::Warehouse::Image.create!(uuid, body, {
      :uuid => uuid,
      :object_type => 'image',
      :template => @template.uuid
    })
    flash.now[:error] = t('images.flash.notice.created')
    if params[:make_deployable]
      redirect_to new_catalog_entry_path(:create_from_image => @image.id)
    else
      redirect_to image_path(@image.id)
    end
  end

  def edit
  end

  def update
  end

  def destroy
    if image = Aeolus::Image::Warehouse::Image.find(params[:id])
      if image.delete!
        flash[:notice] = t('images.flash.notice.deleted')
      else
        flash[:warning] = t('images.flash.warning.delete_failed')
      end
    else
      flash[:warning] = t('images.flash.warning.not_found')
    end
    redirect_to images_path
  end

  def multi_destroy
    selected_images = params[:images_selected].to_a
    selected_images.each do |uuid|
      image = Aeolus::Image::Warehouse::Image.find(uuid)
      image.delete!
    end
    redirect_to images_path, :notice => t("images.flash.notice.multiple_deleted", :count => selected_images.count)
  end

  protected
  def add_template_name(doc, name)
    return unless doc

    if doc.root.nil? || doc.root.name != 'template'
      doc.root = doc.create_element('template')
    end

    if doc.xpath('/template/name').empty?
      doc.xpath('/template').first << doc.create_element('name')
    end

    doc.xpath('/template/name').first.content = name unless name.blank?
  end
end
