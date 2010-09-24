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

module ApplicationHelper

  def confirmation_dialog(div_id, text, action)
    %{
      <div id="#{div_id}" style="display:none;">
        <div class="confirm_dialog_title">
          <div class="confirm_dialog_header">#{text}</div>
          <div style="clear:both;"></div>
        </div>

        <div class="confirm_dialog_footer">
          <div class="button">
            <div class="button_left_grey"></div>
            <div class="button_middle_grey"><a href="#" onclick="$(document).trigger('close.facebox')">Cancel</a></div>
            <div class="button_right_grey"></div>
          </div>
          <div class="button">
            <div class="button_left_blue"></div>
            <div class="button_middle_blue"><a href="#" onclick="#{action}">OK</a></div>
            <div class="button_right_blue"></div>
          </div>
        </div>
      </div>
     }
  end

  def number_to_duration(input_num)
    input_int = input_num.to_i
    hours_to_seconds = [input_int/3600 % 24,
                        input_int/60 % 60,
                        input_int % 60].map{|t| t.to_s.rjust(2,'0')}.join(':')
    days = input_int / 86400
    day_str = ""
    if days > 0
      day_label = (days > 1) ? "days" : "day"
      day_str = "#{days} #{day_label} "
    end
    day_str + hours_to_seconds
  end

  def column_header(column, order, order_dir, check_all)
    next_dir = order_dir.to_s == 'asc' ? 'desc' : 'asc'
    if order and column[:id] == order
      dir = order_dir.to_s == 'desc' ? 'desc' : 'asc'
      cls = "ordercol #{dir}"
    else
      cls = nil
    end

    if column[:sortable]
      label = link_to(
        column[:header],
        {:action => controller.action_name, :partial => true, :order => column[:id], :order_dir => next_dir, :search => params[:search]},
        :class => cls)
    elsif check_all.to_s == column[:id]
      label = check_box_tag 'check_all'
    else
      label = column[:header]
    end

    content_tag 'th', label
  end

  # Fields example:
  # [
  #   { :name => 'Pool name', :sort_attr => 'name'},
  #   { :name => 'Zone', :sortable => false},
  # ]
  def sortable_table_header(fields=[])
    columns = fields.collect do |field|
      if field[:sortable]==true or field[:sortable].nil?
        order_dir = params[:order_dir] ? params[:order_dir] : 'desc'
        if field[:sort_attr].to_s.eql?(params[:order_field])
          class_name = 'active ' + ("desc".eql?(params[:order_dir]) ? 'desc' : 'asc')
        else
          class_name = nil
        end
        content_tag('th', :class => class_name) do
          link_to(field[:name], :controller => params[:controller],
            :action => params[:action], :order_field => field[:sort_attr],
            :order_dir => order_dir.eql?('asc') ? 'desc' : 'asc')
        end
      else
        content_tag('th') do
          field[:name]
        end
      end
    end
    header = content_tag('thead') do
      content_tag('tr') do
        columns.join
      end
    end
  end

  def paginated_table(html_id, columns, data, opts = {})
    search_url = url_for(:partial => true, :order => opts[:order], :order_dir => opts[:order_dir])

    # for now submit url for base table form can be same as search url
    # it's possible to change it in a future
    submit_url = search_url

    extend_table_js = "<script type=\"text/javascript\">Aggregator.extendTable({id: '##{html_id}',single_select:#{opts[:single_select] ? true : false}});#{opts[:load_callback]};</script>"
    extend_sfield_js = "<script type=\"text/javascript\">Aggregator.extendTableSearchField({id: '##{html_id}'})</script>"

    rows = data.map do |rec|
      if block_given?
        capture_haml{yield rec}
      else
        content_tag 'tr', :class => cycle('even', 'odd') do
          columns.map { |c| content_tag 'td', rec[c[:id]] }
        end
      end
    end

    header_cols = columns.map {|c| column_header(c, opts[:order], opts[:order_dir], opts[:check_all])}

    table = content_tag 'table' do
      content_tag('thead', content_tag('tr', header_cols)) + content_tag('tbody', rows)
    end

    internal_header = content_tag 'div', :class => 'header' do
      content_tag('div', opts[:title], :class => 'title')
    end

    internal_footer = content_tag 'div', :class => 'footer' do
      will_paginate(data, :params => {:partial => true}).to_s +
        page_entries_info(data).to_s
    end

    ajax_content = table + internal_footer + extend_table_js

    if params[:partial] and request.xhr?
      ajax_content
    else
      wrapped_table = content_tag 'div', :class => 'wrapped_table' do
        internal_header +
          content_tag('div', ajax_content, :class => 'wrapper')
      end
      base_form = content_tag 'form', :action => submit_url, :class => 'dtable_form' do
        opts[:header].to_s + wrapped_table + opts[:footer].to_s
      end

      # search field is in separate form because of submitting on enter key
      search_field = content_tag 'form', :action => search_url, :class => 'search_field' do
        'Search ' + text_field_tag('search', params[:search], :size => 10, :value => params[:search]) + extend_sfield_js
      end

      content_tag 'div', :id => html_id, :class => "dtable #{opts[:class]}" do
        base_form + search_field
      end
    end
  end
end
