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
#this module contains functions for filtering table data
module CommonFilterMethods
  def apply_filters(options = {})
    filters_options = options[:preset_filters_options] ||
      self::PRESET_FILTERS_OPTIONS
    apply_preset_filter(options[:preset_filter_id], filters_options).
      apply_search_filter(options[:search_filter])
  end

  private

  def apply_preset_filter(preset_filter_id, filters_options)
    if preset_filter_id.present?
      option = filters_options.select { |item|
        item[:id] == preset_filter_id}.first
      if option[:query]
        option[:query]
      else
        includes(option[:includes]).where(option[:where])
      end
    else
      scoped
    end
  end
end
