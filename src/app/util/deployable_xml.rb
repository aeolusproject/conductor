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

require 'util/assembly_xml'

class DeployableXML
  class ValidationError < RuntimeError; end

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    @root = @doc.root.at_xpath('/deployable') if @doc.root
  end

  def name
    @root["name"] if @root
  end

  def description
    node = @root ? @root.at_xpath("description") : nil
    node ? node.text : nil
  end

  def validate!
    raise ValidationError, "Deployable XML root element not found" unless @doc.root
    raise ValidationError, "<deployable> element not found" unless @root
    errors = []
    errors << "deployable name not found" unless name
    if assemblies.size > 0
      assemblies.each do |assembly|
        begin
          assembly.validate!
        rescue AssemblyXML::ValidationError => e
          errors << e.message
        end
      end
    else
      errors << "no assemblies found"
    end
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def assemblies
    @assemblies ||=
      @root.xpath('/deployable/assemblies/assembly').collect do |assembly_node|
      AssemblyXML.new(assembly_node.to_s)
    end
  end

  def image_uuids
    @image_uuids ||= @root.xpath('/deployable/assemblies/assembly/image').collect{|x| x['id']}
  end

  def self.import_xml_from_url(url)
    # Right now we allow this to raise exceptions on timeout / errors
    resource = RestClient::Resource.new(url, :open_timeout => 10, :timeout => 45)
    response = resource.get
    if response.code == 200
      response
    else
      false
    end
  end
end
