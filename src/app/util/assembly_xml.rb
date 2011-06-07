#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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

class AssemblyXML
  class ValidationError < RuntimeError; end

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    @root = @doc.root.at_xpath('/assembly') if @doc.root
    @image = @root.at_xpath('image') if @root
  end

  def to_s
    @root.to_s
  end

  def validate!
    raise ValidationError, "Assembly XML root element not found" unless @doc.root
    raise ValidationError, "<assembly> element not found" unless @root
    errors = []
    errors << "assembly name not found" unless name
    if @image
      if image_id
        errors << "image with uuid #{image_id} not found" unless Image.find(image_id)
        if image_build
          errors << "build with uuid #{image_build} not found" unless ImageBuild.find(image_build)
        end
      else
        errors << "image id not found"
      end
    else
      errors << "<image> element not found"
    end
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def name
    @root["name"] if @root
  end

  def hwp
    @root["hwp"] if @root
  end

  def image_id
    @image["id"] if @image
  end

  def image_build
    @image["build"] if @image
  end

end
