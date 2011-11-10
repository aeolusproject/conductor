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

class CatalogEntriesController < ApplicationController
  before_filter :require_user

  def index
    clear_breadcrumbs
    save_breadcrumb(catalog_catalog_entries_path(:viewstate => @viewstate ? @viewstate.id : nil))
    @catalog_entries = CatalogEntry.list_for_user(current_user, Privilege::VIEW)
    @catalog = @catalog_entries.first.catalog unless @catalog_entries.empty?
    set_header
  end

  def new
    @catalog = Catalog.find(params[:catalog_id])
    @catalog_entry = params[:catalog_entry].nil? ? CatalogEntry.new() : CatalogEntry.new(params[:catalog_entry])
    require_privilege(Privilege::CREATE, CatalogEntry)
    load_catalogs
    @tabs = [t('catalog_entries.new.upload'), t('catalog_entries.new.from_url')]
    @form_option= params[:from_url].nil? ? 'upload' : 'from_url'
    respond_to do |format|
        format.html
        format.js {render :partial => @form_option}
    end
  end

  def show
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::VIEW, @catalog_entry)
    save_breadcrumb(catalog_catalog_entry_path(@catalog_entry.catalog, @catalog_entry), @catalog_entry.name)
  end

  def create
    if params[:cancel]
      redirect_to catalog_catalog_entries_path
      return
    end

    require_privilege(Privilege::CREATE, CatalogEntry)
    require_privilege(Privilege::MODIFY, @catalog)
    @catalog_entry = CatalogEntry.new(params[:catalog_entry])
    @catalog_entry.owner = current_user

    if @catalog_entry.save
      flash[:notice] = t "catalog_entries.flash.notice.added"
      flash[:warning] = t("catalog_entries.flash.warning.not_valid") unless @catalog_entry.valid_deployable_xml?
      if params[:edit_xml]
        redirect_to edit_catalog_catalog_entry_path @catalog_entry.catalog.id, @catalog_entry.id, :edit_xml =>true
      else
        redirect_to catalog_catalog_entries_path(@catalog)
      end
    else
      @catalog = Catalog.find(params[:catalog_id])
      load_catalogs
      params.delete(:edit_xml) if params[:edit_xml]
      render :new
    end
  end

  def edit
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, @catalog_entry)
    @catalog = @catalog_entry.catalog
    load_catalogs
  end

  def update
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, @catalog_entry)
    params[:catalog_entry].delete(:owner_id) if params[:catalog_entry]

    if @catalog_entry.update_attributes(params[:catalog_entry])
      flash[:notice] = t"catalog_entries.flash.notice.updated"
      redirect_to catalog_catalog_entry_path(@catalog_entry.catalog, @catalog_entry)
    else
      load_catalogs
      render :action => 'edit'
    end
  end

  def multi_destroy
    @catalog = nil
    CatalogEntry.find(params[:catalog_entries_selected]).to_a.each do |d|
      require_privilege(Privilege::MODIFY, d)
      @catalog = d.catalog
      d.destroy
    end
    redirect_to catalog_path(@catalog)
  end

  def destroy
    catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, catalog_entry)
    @catalog = catalog_entry.catalog
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

  def redirect_to_deployable_xml?

  end

  def load_catalogs
    @catalogs = Catalog.list_for_user(current_user, Privilege::MODIFY)
  end
end
