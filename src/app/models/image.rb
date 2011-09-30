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

  # The iwhd API really isn't built for what we're trying to do.
  # Here's a nutty workaround to not issues thousands of queries.
  # images should be an array of Aeolus::Image::Warehouse::Image objects
  # Please don't shoot me for this!
  def self.provider_images_for_image_list(images)
    # Fetch all of these, but only once
    provider_images = Aeolus::Image::Warehouse::ProviderImage.all
    target_images = Aeolus::Image::Warehouse::TargetImage.all
    builds = Aeolus::Image::Warehouse::ImageBuild.all
    return_objs = {}
    images.each do |image|
      _builds = builds.select{|b| b.instance_variable_get('@image') == image.uuid}
      _builds.each do |build|
        _target_images = target_images.select{|ti| ti.instance_variable_get('@build') == build.uuid}
        _target_images.each do |target_image|
          _provider_images = provider_images.select{|pi| pi.instance_variable_get('@target_image') == target_image.uuid}
          return_objs[image.uuid] = _provider_images
        end
      end
    end
    return_objs
  end

end
