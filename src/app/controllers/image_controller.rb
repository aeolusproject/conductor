#
# Copyright (C) 2009 Red Hat, Inc.
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

class ImageController < ApplicationController
  before_filter :require_user

  def index
  end

  def show
    # FIXME: check on privilege IMAGE_VIEW which currently doesn't exist
    #require_privilege(Privilege::POOL_VIEW, @pool)
  end

  def images_paginate
    # FIXME: check on privilege IMAGE_VIEW which currently doesn't exist
    #require_privilege(Privilege::POOL_VIEW, @pool)

    # datatables sends pagination in format:
    #   iDisplayStart - start index
    #   iDisplayLength - num of recs
    # => we need to count page num
    page = params[:iDisplayStart].to_i / Image::per_page

    if params[:mode].to_s == 'simple'
      simple_mode = true
      cols = Image::COLUMNS_SIMPLE
      default_order_col = 1
    else
      cols = Image::COLUMNS
      simple_mode = false
      default_order_col = 2
    end

    order_col_rec = cols[params[:iSortCol_0].to_i]
    order_col = cols[default_order_col] unless order_col_rec && order_col_rec[:opts][:searchable]
    order = order_col[:id] + " " + (params[:sSortDir_0] == 'desc' ? 'desc' : 'asc')

    @images = Image.search_filter(params[:sSearch], Image::SEARCHABLE_COLUMNS).paginate(
      :page => page + 1,
      :include => :instances,
      :order => order,
      :conditions => {:provider_id => nil}
    )

    expand_button_html = "<img src='/images/dir_closed.png'>"

    data = @images.map do |i|
      if simple_mode
        [i.id, i.name, i.architecture, i.instances.size]
      else
        [i.id, expand_button_html, i.name, i.architecture, i.instances.size, "TODO: some description here?"]
      end
    end

    render :json => {
      :sEcho => params[:sEcho],
      :iTotalRecords => @images.total_entries,
      :iTotalDisplayRecords => @images.total_entries,
      :aaData => data
    }
  end

end
