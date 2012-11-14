#
#   Copyright 2012 Red Hat, Inc.
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

# Before filter for controllers that handle REST API requests. Conductor uses
# linking to resources like <pool id='1'/> (resulting in :pool => { :id => 1 }
# in request params hash) but ActiveRecord expects linking to resources like
# <pool_id>1</pool_id> (resluting in :pool_id => 1 in request params hash).
#
# This before filter operates on request params hash to rewrite it from our
# format to ActiveRecord-friendly format.
#
# The constructor of the filter accepts specification of what should be
# transformed. E.g.:
#
#  before_filter ResourceLinkFilter.new({ :catalog => :pool }),
#                :only => [:create, :update]
#
# would transform { :catalog => { :pool => { :id => 1 }}}
# into            { :catalog => { :pool_id => 1 }}
#
# See the specs in spec/util/resource_link_filter_spec.rb for more examples.
#
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
