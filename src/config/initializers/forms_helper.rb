# This adds back in the id to the generated html for the submit tag, as it
# was in Rails 3.0.x.  We use this id, and it keeps our app compatible between
# Rais versions

class ActionView::Helpers::FormBuilder

  def submit(value=nil, options={})
    value, options = nil, value if value.is_a?(Hash)
    value ||= submit_default_value
    @template.submit_tag(value,
                         options.reverse_merge(:id => "#{object_name}_submit"))
  end

end
