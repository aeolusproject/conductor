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


class Image < WarehouseModel
  @bucket_name = 'images'

  def initialize(attrs)
    attrs.each do |k,v|
      if k.to_sym == :latest_build
        sym = :attr_writer
      else
        sym = :attr_accessor
      end
      self.class.send(sym, k.to_sym) unless respond_to?(:"#{k}=")
      send(:"#{k}=", v)
    end
  end

  def latest_build
    ImageBuild.find(@latest_build) if @latest_build
  end

  def image_builds
    ImageBuild.find_all_by_image_uuid(self.uuid)
  end
end
