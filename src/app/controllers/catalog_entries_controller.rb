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

  def create
    @catalog_entry = CatalogEntry.new(params[:catalog_entry])
    require_privilege(Privilege::MODIFY, @catalog_entry.catalog)
    require_privilege(Privilege::MODIFY, @catalog_entry.deployable)

    if @catalog_entry.save
      redirect_to catalog_deployable_path(@catalog_entry.catalog, @catalog_entry), :notice => t('catalog_entries.flash.notice.added')
    else
      flash[:warning] = t('catalog_entries.flash.warning.failed')
      redirect_to catalog_deployable_path(@catalog_entry.catalog, @catalog_entry.deployable.catalog_entries.first)
    end
  end

  def destroy
    @catalog_entry = CatalogEntry.find(params[:id])
    deployable = @catalog_entry.deployable
    catalog = @catalog_entry.catalog

    require_privilege(Privilege::MODIFY, @catalog_entry.catalog)
    require_privilege(Privilege::MODIFY, @catalog_entry.deployable)
    @catalog_entry.destroy

    if deployable.catalog_entries.empty?
      redirect_to catalog_path(catalog), :notice => t('catalog_entries.flash.notice.deleted')
    else
      catalog_entry_to_nagigate = deployable.catalog_entries.first
      redirect_to catalog_deployable_path(catalog_entry_to_nagigate.catalog, catalog_entry_to_nagigate), :notice => t('catalog_entries.flash.notice.deleted')
    end

  end

end
