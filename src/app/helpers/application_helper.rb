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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module ApplicationHelper
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

  # Fields example:
  # [
  #   { :name => 'Pool name', :sort_attr => 'name'},
  #   { :name => 'Pool family', :sortable => false},
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
        columns.join.html_safe
      end
    end
  end

  def filter_table(columns, rows, options={}, &block)
    _class = rows.first.try(:class) || Object
    filter_widgets_opts = options[:show_filter_widgets]
    select_togle_opts = options[:show_select_toggle]
    render :partial => 'layouts/filter_table', :locals => {
        :form_header => options[:form_header] || :form_header,
        :form_footer => options[:form_footer] || :form_footer,
        # TODO - Right now saved_searches are not functional; this will need to be expanded
        :saved_searches => ["<option>All #{_class.name.pluralize}</option>"],
        :object_count => rows.count,
        # TODO - We need to support searches and filters below
        :search_term => nil,
        :filters => {},
        :columns => columns,
        :lower_class => _class.to_s.tableize,
        :block => block,
        :rows => rows,
        :show_filter_widgets => filter_widgets_opts.nil? ? false : filter_widgets_opts,
        :show_select_toggle => select_togle_opts.nil? ? true : select_togle_opts,
    }
  end

  # Integration of rack-restful_submit convention to be able to call
  # RESTful resources defined by Rails conventions without Javascript.
  #
  # Method generates 3 tags:
  # * 2 hidden field tags to define URL and METHOD to be forwared to in RESTful env.
  # * 1 submit field to trigger the form submission defining the action
  #
  # Example:
  #   <tt>restful_submit_tag('Delete', 'destroy', instance_path(@instance), 'DELETE')</tt>
  #
  # Learn more: https://github.com/martincik/rack-restful_submit
  def restful_submit_tag(value, action, url, method, options = {})
    hidden_field_tag("__map[#{action}][url]", url) <<
    hidden_field_tag("__map[#{action}][method]", method.upcase) <<
    submit_tag(value, {:name => "__rewrite[#{action}]"}.reverse_merge!(options))
  end

  def slug(title)
    title.split(' ').join('_').downcase
  end

  def count_uptime(time)
    if time
      result_string = []

      seconds = time % 60
      time = (time - seconds) / 60
      minutes = time % 60
      time = (time - minutes) / 60
      hours = time % 24
      time = (time - hours)   / 24
      days = time % 7

      result_string<< "#{days.to_i} #{(days.to_i > 1 ? 'days' : 'day')}" if days != 0
      result_string<<"#{"%02d"%hours.to_i}:#{"%02d"%minutes.to_i}:#{"%02d"%seconds.to_i}"
      result_string.join(", ")
    else
      "N/A"
    end
  end

  def owner_name(obj)
    return '' unless obj.owner
    # if last_name is set, use full name,
    # else use login
    if obj.owner.last_name.blank?
      obj.owner.login
    else
      "#{obj.owner.first_name} #{obj.owner.last_name}"
    end
  end

  def pretty_filter_toggle(pretty_link, filter_link)
    render :partial => 'layouts/pretty_filter_toggle', :locals => {
      :pretty_link => pretty_link,
      :filter_link => filter_link
    }
  end

  def javascript?
    session[:javascript_enabled]
  end

  def get_hash_multi(hash, keys)
    keys.reduce(hash) {|h, k| h[k] if (h and h.respond_to? :keys) }
  end

  module_function :count_uptime
end
