#this module contains functions for filtering table data
module CommonFilterMethods
  def apply_filters(options = {})
    apply_preset_filter(options[:preset_filter_id]).apply_search_filter(options[:search_filter])
  end

  private

  def apply_preset_filter(preset_filter_id)
    if preset_filter_id.present?
      self::PRESET_FILTERS_OPTIONS.select{|item| item[:id] == preset_filter_id}.first[:query]
    else
      scoped
    end
  end
end
