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

module ApplicationHelper

  include MustacheHelper

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

  def filter_table(columns, rows, options = {}, &block)
    _class = rows.first.try(:class) || Object
    render :partial => 'layouts/filter_table', :locals => {
        :form_header => options[:form_header] || :form_header,
        :filter_controls => options[:filter_controls] || :filter_controls,
        :form_footer => options[:form_footer] || :form_footer,
        :object_count => rows.count,
        :columns => columns,
        :lower_class => _class.to_s.tableize,
        :block => block,
        :rows => rows,
    }
  end

  #generates options for preset filters select, which can be reduced by specifying preset_filters_ids
  def preset_filters_options_for_select(all_preset_filters_options, selected, preset_filters_ids = nil)
    if preset_filters_ids
      preset_filters_options = all_preset_filters_options.select{|item| preset_filters_ids.include?(item[:id])}
    else
      preset_filters_options = all_preset_filters_options
    end
    options_for_select(preset_filters_options.collect{|x| [I18n.t(x[:title]), x[:id]]}, :selected => selected)
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

  def count_uptime(delta_seconds)
    if delta_seconds
      seconds = delta_seconds.to_i
      minutes = seconds / 60
      hours = minutes / 60
      days = hours / 24
      months = days / 31

      case
      when months > 0
        I18n.t('datetime.distance_in_words.x_months', :count => months)
      when days > 0
        I18n.t('datetime.distance_in_words.x_days', :count => days)
      when hours > 0
        I18n.t('datetime.distance_in_words.x_hours', :count => hours)
      when minutes > 0
        I18n.t('datetime.distance_in_words.x_minutes', :count => minutes)
      else
        I18n.t('datetime.distance_in_words.x_seconds', :count => seconds)
      end
    else
      "N/A"
    end
  end
  module_function :count_uptime

  def owner_name(obj)
    return '' unless obj.owner
    # if last_name is set, use full name,
    # else use username
    if obj.owner.last_name.blank?
      obj.owner.username
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

  def render_pagination(collection)
    will_paginate(collection, :previous_label => _("&#8592; Previous"), :next_label => _("Next &#8594;"))
  end

  # FIXME: remove this once we remove nested routes for provider accounts.
  def provider_account_path(account)
    "/providers/#{account.provider_id}/provider_accounts/#{account.id}"
  end

  def conductor_form_for(object, options={}, &block)
    error_partial = 'layouts/simple_form_error_messages'
    if options.has_key?(:error_partial)
      error_partial = options.delete(:error_partial)
    end

    render(error_partial, :object => object) if object.errors.any?
    simple_form_for(object, options, &block)
  end

end
