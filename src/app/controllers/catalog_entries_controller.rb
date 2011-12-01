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
