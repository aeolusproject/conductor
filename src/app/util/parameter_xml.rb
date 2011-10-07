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

class ParameterXML
  class ValidationError < RuntimeError; end
=begin Parameter XML Format
  <parameter name="service_configuration_parameter_name" type="scalar" default="default_value"/>

  <parameter name="service_configuration_parameter_name" type="scalar">
    <reference assembly="other_assembly_name" service="other_assembly_service_name"
        parameter="other_assembly_parameter_name"/>
  </parameter>

  <parameter name="service_configuration_parameter_name" type="scalar">
    <reference assembly="other_assembly_name" parameter="other_assembly_parameter_name"/>
  </parameter>
=end

  class ParameterReferenceXML
    def initialize(xmlstr = "")
      @doc = Nokogiri::XML(xmlstr)
      @root = @doc.root.at_xpath('/reference') if @doc.root
    end

    def to_s
      @root.to_s
    end

    def validate!
      raise ValidationError, "Reference XML root element not found" unless @doc.root
      raise ValidationError, "<reference> element not found" unless @root
      errors = []
      errors << "reference assembly name not found" unless assembly
      errors << "reference parameter name not found" unless parameter
      raise ValidationError, errors.join(", ") unless errors.empty?
    end

    def assembly
      @root['assembly'] if @root
    end

    def service
      @root['service'] if @root
    end

    def parameter
      @root['parameter'] if @root
    end
  end

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    @root = @doc.root.at_xpath('/parameter') if @doc.root
  end

  def to_s
    @root.to_s
  end

  def validate!
    raise ValidationError, "Parameter XML root element not found" unless @doc.root
    raise ValidationError, "<parameter> element not found" unless @root
    errors = []
    errors << "parameter name not found" unless name
    errors << "parameter type not found" unless type
    if reference
      begin
        reference.validate!
      rescue ValidationError => e
        errors << e.message
      end
    end
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def name
    @root['name'] if @root
  end

  def type
    @root['type'] if @root
  end

  def default?
    not default.nil?
  end

  def reference?
    not reference.nil?
  end

  def default
    @root['default'] if @root
  end

  def reference
    @reference ||= if @root and @root.at_xpath('reference')
      ParameterReferenceXML.new(@root.at_xpath('reference').to_s)
    end
  end
end
