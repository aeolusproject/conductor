class ResourceLinkFilter
  def initialize(resource_links)
    @resource_links = resource_links
  end

  def before(controller)
    return unless controller.request.format == :xml

    transform_resource_links_recursively(controller.params, @resource_links)
  end


  private

  def transform_resource_links_recursively(subparams, sublinks)
    return if subparams == nil

    case sublinks
    when Symbol # then transform the link (last level of recursion)
      return if subparams[sublinks] == nil || subparams[sublinks][:id] == nil

      subparams[:"#{sublinks}_id"] = subparams[sublinks][:id]
      subparams.delete(sublinks)
    when Array # then process each item
      sublinks.each do |item|
        transform_resource_links_recursively(subparams, item)
      end
    when Hash # then descend into each entry
      sublinks.each_key do |key|
        transform_resource_links_recursively(subparams[key], sublinks[key])
      end
    end
  end
end
