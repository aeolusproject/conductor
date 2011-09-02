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
    save_breadcrumb(catalog_entries_path(:viewstate => @viewstate ? @viewstate.id : nil))
    @catalog_entries = CatalogEntry.list_for_user(current_user, Privilege::VIEW)
    set_header
  end

  def new
    @catalog_entry = CatalogEntry.new(params[:catalog_entry])
    require_privilege(Privilege::CREATE, CatalogEntry)
    load_catalogs
  end

  def show
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::VIEW, @catalog_entry)
    save_breadcrumb(catalog_entry_path(@catalog_entry), @catalog_entry.name)
  end

  def create
    if params[:cancel]
      redirect_to catalog_entries_path
      return
    end

    require_privilege(Privilege::CREATE, CatalogEntry)
    @catalog_entry = CatalogEntry.new(params[:catalog_entry])
    @catalog_entry.owner = current_user
    if @catalog_entry.save
      flash[:notice] = 'Catalog entry added'
      flash[:warning] = "Deployable url doesn't resolve valid XML file" unless @catalog_entry.accessible_and_valid_deployable_xml?(@catalog_entry.url)
      redirect_to catalog_entries_path
    else
      load_catalogs
      render :new
    end
  end

  def edit
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, @catalog_entry)
    load_catalogs
  end

  def update
    @catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, @catalog_entry)
    params[:catalog_entry].delete(:owner_id) if params[:catalog_entry]

    if @catalog_entry.update_attributes(params[:catalog_entry])
      flash[:notice] = 'Catalog entry updated successfully!'
      redirect_to catalog_entries_url
    else
      load_catalogs
      render :action => 'edit'
    end
  end

  def multi_destroy
    CatalogEntry.find(params[:catalog_entries_selected]).to_a.each do |d|
      require_privilege(Privilege::MODIFY, d)
      d.destroy
    end
    redirect_to catalog_entries_path
  end

  def destroy
    catalog_entry = CatalogEntry.find(params[:id])
    require_privilege(Privilege::MODIFY, catalog_entry)
    catalog_entry.destroy

    respond_to do |format|
      format.html { redirect_to catalog_entries_path }
    end
  end

  private

  def set_header
    @header = [
      { :name => '', :sortable => false },
      { :name => t("catalog_entries.index.name"), :sort_attr => :name },
      { :name => t("catalogs.index.catalog_name"), :sortable => false },
      { :name => t("catalog_entries.index.url"), :sortable => :url }
    ]
  end

  def load_catalogs
    @catalogs = Catalog.list_for_user(current_user, Privilege::MODIFY)
  end
end
