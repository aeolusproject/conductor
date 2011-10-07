#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Greg Blomquist <gblomqui@redhat.com>
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
require 'util/parameter_xml'

class ServiceXML
  class ValidationError < RuntimeError; end
=begin Service XML Format
  <service name="service_name">
    <parameters> ... (see parameter_xml.rb) </parameters>
    <tooling> ... (see config_tooling_xml.rb) </tooling>
  </service>
=end

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    @root = @doc.root.at_xpath('/service') if @doc.root
  end

  def to_s
    @root.to_s
  end

  def validate!
    raise ValidationError, "Service XML root element not found" unless @doc.root
    raise ValidationError, "<service> element not found" unless @root
    errors = []
    errors << "service name not found" unless name
    if config_tooling
      begin
        config_tooling.validate!
      rescue ConfigToolingXML::ValidationError => e
        errors << e.message
      end
    end
    unless parameters.empty?
      parameters.each do |parameter|
        begin
          parameter.validate!
        rescue ParameterXML::ValidationError => e
          errors << e.message
        end
      end
    end
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def name
    @root['name'] if @root
  end

  def parameters
    @parameters ||=
      @root.xpath('parameters/parameter').collect do |parameter_node|
      ParameterXML.new(parameter_node.to_s)
    end
  end

  def config_tooling
    @config_tooling ||= if @root and @root.at_xpath('tooling')
      ConfigToolingXML.new(@root.at_xpath('tooling').to_s)
    end
  end
end
