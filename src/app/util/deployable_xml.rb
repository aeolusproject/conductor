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

=begin
XML Wrapper objects for the deployable XML format
=end

class ValidationError < RuntimeError; end

class ParameterXML
  def initialize(node)
    @root = node
  end

  def name
    @root['name']
  end

  def type
    @root['type']
  end

  def value
    value_node.content if value_node
  end

  def value=(value)
  end

  def reference?
    not reference_node.nil?
  end

  def reference_assembly
    reference_node['assembly'] if reference?
  end

  def reference_parameter
    reference_node['parameter'] if reference?
  end

  # shortcut method for accessing ref as a string
  def reference_string
    if reference?
      if reference_service
        "REF::$(#{reference_assembly}).$(#{reference_service}).$(#{reference_parameter})"
      else
        "REF::$(#{reference_assembly}).$(#{reference_parameter})"
      end
    end
  end

  private
  def reference_node
    @reference ||= @root.at_xpath("./reference")
  end

  def value_node
    @value_node ||= @root.at_xpath("./value")
  end

  def value_node=(value)
    @root.content = "<value><![CDATA[#{value}]]></value>"
  end

end

class ServiceXML
  def initialize(name, executable, files, parameters)
    @name = name
    @executable = executable
    @file_nodes = files || []
    @parameter_nodes = parameters || []
  end
  def name; @name; end

  def executable
    @executable['url'] if @executable
  end

  def files
    @files ||= @file_nodes.collect do |file_node|
      file_node['url']
    end
  end

  def parameters
    @parameters ||= @parameter_nodes.collect do |param_node|
      ParameterXML.new(param_node)
    end
  end
end

class AssemblyXML

  def initialize(xmlstr_or_node = "")
    if xmlstr_or_node.is_a? Nokogiri::XML::Node
      @root = xmlstr_or_node
    else
      doc = Nokogiri::XML(xmlstr_or_node)
      @root = doc.at_xpath("./assembly") if doc.root
    end
  end

  def validate!
    errors = []
    #errors << "image with uuid #{image_id} not found" unless Image.find(image_id)
    #if image_build
      #errors << "build with uuid #{image_build} not found" unless ImageBuild.find(image_build)
    #end
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def image
    @image ||= @root.at("image")
  end

  def image_id
    @image_id ||= image['id']
  end

  def name
    @name ||= @root['name']
  end

  def hwp
    @hwp ||= @root['hwp']
  end

  def image_build
    @image_build ||= image['build']
  end

  def services
    # services and top-level tooling are mutually exclusive
    @services ||= collect_services || []
  end

  def to_s
    @root.to_s
  end

  def output_parameters
    @output_parameters ||=
      @root.xpath('returns/return').collect do |output_param|
      output_param['name']
    end
  end

  def requires_config_server?
    not (services.empty? and output_parameters.empty?)
  end

  def to_s
    @root.to_s
  end

  private
  def collect_services
    # collect the service level tooling
    nil_if_empty(@root.xpath("./services/service").collect do |service|
      name = service['name']
      exe = service.at_xpath("./executable")
      files = service.xpath("./files/file")
      parameters = service.xpath("./parameters/parameter")
      ServiceXML.new(name, exe, files, parameters)
    end)
  end

  def nil_if_empty(array)
    array unless array.nil? or array.empty?
  end
end


class DeployableXML

  def initialize(xmlstr_or_node = "")
    if xmlstr_or_node.is_a? Nokogiri::XML::Node
      @root = xmlstr_or_node
    elsif xmlstr_or_node.is_a? String
      @doc = Nokogiri::XML(xmlstr_or_node)
      @root = @doc.root.at_xpath("/deployable") if @doc.root
    end
    @relax_file = "#{File.dirname(File.expand_path(__FILE__))}/deployable-rng.xml"
  end

  def name
    @root["name"] if @root
  end

  def description
    node = @root ? @root.at_xpath("description") : nil
    node ? node.text : nil
  end

  def validate!
    # load the relaxNG file and validate
    errors = relax.validate(@root.document) || []
    # ...and validate the assembly
    assemblies.each do |assembly|
      begin
        assembly.validate!
      rescue ValidationError => e
        errors << e.message
      end
    end
    raise ValidationError, errors.join(", ") unless errors.empty?
  end

  def assemblies
    @assemblies ||=
      @root.xpath('/deployable/assemblies/assembly').collect do |assembly_node|
      AssemblyXML.new(assembly_node)
    end
  end

  def image_uuids
    @image_uuids ||= @root.xpath('/deployable/assemblies/assembly/image').collect{|x| x['id']}
  end

  def set_parameter_value(assembly, service, parameter, value)
    # Why not do this in the ParameterXML class?
    # B/c we need to alter the deployable XML document and not the copy at the
    # ParameterXML object
    xpath = "//assembly[@name='#{assembly}']//service[@name='#{service}']//parameter[@name='#{parameter}']"
    param = @root.at_xpath(xpath)
    param.inner_html = "<value><![CDATA[#{value}]]></value>" if param
    @assemblies = nil # reset assemblies
  end

  def requires_config_server?
    assemblies.any? {|assembly| assembly.requires_config_server? }
  end

  def to_s
    @root.to_s
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

  private
  def relax
    @relax ||= File.open(@relax_file) {|f| Nokogiri::XML::RelaxNG(f)}
  end
end
