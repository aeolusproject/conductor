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
require 'uri'

class CatalogEntriesController < ApplicationController
  before_filter :require_user

  def index
    clear_breadcrumbs
    save_breadcrumb(catalog_catalog_entries_path(:viewstate => @viewstate ? @viewstate.id : nil))
    @deployables = Deployable.list_for_user(current_user, Privilege::VIEW)
    @catalog_entries = @deployables.collect { |d| d.catalog_entries.first }
    @catalog = @catalog_entries.first.catalog unless @catalog_entries.empty?
    set_header
  end

  def new
    @catalog = Catalog.find(params[:catalog_id])
    @catalog_entry = params[:catalog_entry].nil? ? CatalogEntry.new() : CatalogEntry.new(params[:catalog_entry])
    @catalog_entry.deployable = Deployable.new unless @catalog_entry.deployable
    require_privilege(Privilege::MODIFY, @catalog)
    require_privilege(Privilege::CREATE, Deployable)
    @form_option= params.has_key?(:from_url) ? 'from_url' : 'upload'
    respond_to do |format|
        format.html
        format.js {render :partial => @form_option}
    end
  end

  def show
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::VIEW, @catalog_entry.deployable)
    save_breadcrumb(catalog_catalog_entry_path(@catalog_entry.catalog, @catalog_entry), @catalog_entry.deployable.name)
  end

  def create
    if params[:cancel]
      redirect_to catalog_catalog_entries_path
      return
    end

    @catalog = Catalog.find(params[:catalog_id])
    require_privilege(Privilege::MODIFY, @catalog)
    require_privilege(Privilege::CREATE, Deployable)
    @catalog_entry = CatalogEntry.new(params[:catalog_entry])
    @catalog_entry.catalog = @catalog
    @catalog_entry.deployable.owner = current_user

    if params.has_key? :url
        xml = import_xml_from_url(params[:url])
        unless xml.nil?
          #store xml_filename for url (i.e. url ends to: foo || foo.xml)
          @catalog_entry.deployable.xml_filename =  File.basename(URI.parse(params[:url]).path)
          @catalog_entry.deployable.xml = xml
        end
    end

    if @catalog_entry.save
      flash[:notice] = t "catalog_entries.flash.notice.added"
      if params[:edit_xml]
        redirect_to edit_catalog_catalog_entry_path @catalog_entry.catalog.id, @catalog_entry.id, :edit_xml =>true
      else
        redirect_to catalog_catalog_entries_path(@catalog)
      end
    else
      @catalog = Catalog.find(params[:catalog_id])
      params.delete(:edit_xml) if params[:edit_xml]
      flash[:warning]= t('catalog_entries.flash.warning.not_valid') if @catalog_entry.errors.has_key?(:xml)
      @form_option = params[:catalog_entry][:deployable].has_key?(:xml) ? 'upload' : 'from_url'
      render :new
    end
  end

  def edit
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, @catalog_entry.deployable)
    @catalog = @catalog_entry.catalog
  end

  def update
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, @catalog_entry.deployable)
    params[:catalog_entry][:deployable].delete(:owner_id) if params[:catalog_entry] and params[:catalog_entry][:deployable]

    if @catalog_entry.update_attributes(params[:catalog_entry])
      flash[:notice] = t"catalog_entries.flash.notice.updated"
      redirect_to catalog_catalog_entry_path(@catalog_entry.catalog, @catalog_entry)
    else
      render :action => 'edit'
    end
  end

  def multi_destroy
    @catalog = nil
    CatalogEntry.find(params[:catalog_entries_selected]).to_a.each do |d|
      require_privilege(Privilege::MODIFY, d.catalog)
      require_privilege(Privilege::MODIFY, d.deployable)
      @catalog = d.catalog
      # Don't do this when we're managing deployables independently
      d.deployable.destroy
      d.destroy
    end
    redirect_to catalog_path(@catalog)
  end

  def destroy
    catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, catalog_entry.catalog)
    require_privilege(Privilege::MODIFY, catalog_entry.deployable)
    @catalog = catalog_entry.catalog
    # Don't do this when we're managing deployables independently
    catalog_entry.deployable.destroy
    catalog_entry.destroy

    respond_to do |format|
      format.html { redirect_to catalog_path(@catalog) }
    end
  end

  private

  def set_header
    @header = [
      { :name => 'checkbox', :class => 'checkbox', :sortable => false },
      { :name => t("catalog_entries.index.name"), :sort_attr => :name },
      { :name => t("catalogs.index.catalog_name"), :sortable => false },
      { :name => t("catalog_entries.index.deployable_xml"), :sortable => :url }
    ]
  end

  def load_catalogs
    @catalogs = Catalog.list_for_user(current_user, Privilege::MODIFY)
  end

  def import_xml_from_url(url)
    begin
      response = RestClient.get(url, :accept => :xml)
      if response.code == 200
        response
      end
    rescue RestClient::Exception, SocketError, URI::InvalidURIError
      flash[:error] = t('catalog_entries.flash.warning.not_valid_or_reachable', :url => url)
      nil
    end
  end
end
