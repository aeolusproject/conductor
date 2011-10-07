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

require 'util/config_tooling_xml'
require 'util/service_xml'

class AssemblyXML
  class ValidationError < RuntimeError; end
=begin Assembly XML Format
  <assembly name="assembly_name" hwp="hardware_profile">
    <image id="image_id"/>
    <tooling> ... (see config_tooling_xml.rb) </tooling>
    <services> ... (see service_xml.rb) </services>
  </assembly>
=end

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    @root = @doc.root.at_xpath('/assembly') if @doc.root
    @image = @root.at_xpath('image') if @root
  end

  def to_s
    @root.to_s
  end

  def validate!
    # hmm...seems like all this validation should be replaced by relaxNG
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
    if config_tooling
      begin
        config_tooling.validate!
      rescue ConfigToolingXML::ValidationError => e
        errors << e.message
      end
    end
    unless services.empty?
      services.each do |service|
        begin
          service.validate!
        rescue ServiceXML::ValidationError => e
          errors << e.message
        end
      end
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

  def requires_config_server?
    not (config_tooling.nil? and services.empty? and output_parameters.empty?)
  end

  def config_tooling
    @config_tooling ||= if @root and @root.at_xpath('tooling')
      ConfigToolingXML.new(@root.at_xpath('tooling').to_s)
    end
  end

  def services
    @services ||=
      @root.xpath('services/service').collect do |service_node|
      ServiceXML.new(service_node.to_s)
    end
  end

  def output_parameters
    @output_parameters ||=
      @root.xpath('returns/parameter').collect do |parameter_node|
      parameter_node['name']
    end
  end
end
