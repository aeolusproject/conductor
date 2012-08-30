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

=begin
XML Wrapper objects for the deployable XML format
=end

require 'tsort'

class ValidationError < RuntimeError; end

class ParameterXML
  def initialize(node)
    @root = node
  end

  def name
    @root['name']
  end

  def type
    if value_node
      value_node['type'] || @root['type']
    else
      "Scalar"
    end
  end

  def type_warning
    # providing a place to see the old placement of the type
    # attr directly so we can check it and throw warnings.
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

  def reference_service
    reference_node['service'] if reference?
  end

  def reference_parameter
    reference_node['parameter'] if reference?
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
  def initialize(name, description, executable, files, parameters)
    @name = name
    @description = description
    @executable = executable
    @files = files || []
    @parameter_nodes = parameters || []
  end
  attr_reader :name, :description, :executable, :files

  def parameters
    @parameters ||= @parameter_nodes.collect do |param_node|
      ParameterXML.new(param_node)
    end
  end

  def references
    refs = parameters.map do |param|
      next unless param.reference?
      {:assembly => param.reference_assembly,
       :service => param.reference_service,
       :param => param.reference_parameter,
       :from_param => param.name}
    end.compact
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

  def images_count
    @root.xpath('./image').count
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

  def dependency_nodes
    nodes = services.map do |service|
      {:assembly => name,
       :service => service.name,
       :references => service.references}
    end
    # whole assembly is added as a node too because a inter-assembly references
    # reference whole assembly, not particular service
    nodes << {:assembly => name,
              :service => nil,
              :references => nodes.map {|n|
                               n[:references]}.flatten}
  end

  private
  def collect_services
    # collect the service level tooling
    nil_if_empty(@root.xpath("./services/service").collect do |service|
      name = service['name']
      description = service.at_xpath('./description')
      exe = service.at_xpath("./executable")
      files = service.xpath("./files/file")
      parameters = service.xpath("./parameters/parameter")
      ServiceXML.new(name, (description and description.text), exe, files, parameters)
    end)
  end

  def nil_if_empty(array)
    array unless array.nil? or array.empty?
  end
end


class DeployableXML

  DEPLOYABLE_VERSION = "1.0"
  def self.version
    DEPLOYABLE_VERSION
  end

  def initialize(xmlstr_or_node = "")
    if xmlstr_or_node.is_a? Nokogiri::XML::Node
      @root = xmlstr_or_node
    elsif xmlstr_or_node.is_a? String
      doc = Nokogiri::XML(xmlstr_or_node) { |config| config.strict }
      @root = doc.root.at_xpath("/deployable") if doc.root
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
    return false if @root.nil?
    errors = relax.validate(@root.document) || []
    # ...and validate the assembly
    assemblies.each do |assembly|
      begin
        assembly.validate!
      rescue ValidationError => e
        errors << e.message
      end
    end
    errors.empty?
  end

  def unique_assembly_names?
    @root.xpath("/deployable/assemblies/assembly/@name").collect { |e| e.value }.uniq!.nil?
  end

  def assemblies
    return [] unless @root
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

  def dependency_graph
    @dependency_graph ||= DeployableDependencyGraph.new(assemblies)
  end

  private

  def relax
    @relax ||= File.open(@relax_file) {|f| Nokogiri::XML::RelaxNG(f)}
  end
end

class DeployableDependencyGraph
  include TSort

  def initialize(assemblies)
    @assemblies = assemblies
  end

  def cycles
    strongly_connected_components.find_all {|c| c.length > 1}
  end

  def dependency_nodes
    @nodes ||= @assemblies.map {|assembly| assembly.dependency_nodes}.flatten
  end

  def tsort_each_node(&block)
    dependency_nodes.each(&block)
  end

  def tsort_each_child(node, &block)
    node[:references].map do |ref|
      ref_node = dependency_nodes.find do |n|
        n[:assembly] == ref[:assembly] && n[:service] == ref[:service]
      end
      ref[:not_existing_ref] = true unless ref_node
      ref_node
    end.compact.each(&block)
  end

  def not_existing_references
    # not_existing references are detected when doing tsort
    strongly_connected_components

    invalid_refs = []
    dependency_nodes.each do |node|
      # skip "whole assembly" nodes
      next unless node[:service]

      node[:references].each do |ref|
        if ref[:not_existing_ref]
          # in this case, the referenced assembly/service doesn't exist
          # at all
          invalid_refs << {:assembly => node[:assembly],
                           :service => node[:service],
                           :reference => ref}
        else
          # in this case, the referenced assembly/service exists, but the
          # referenced parameter is not listed in <returns> tag of the assembly
          assembly = @assemblies.find {|a| a.name == ref[:assembly]}
          next unless assembly # this shouldn't be needed
          unless assembly.output_parameters.include?(ref[:param])
            invalid_refs << {:assembly => node[:assembly],
                             :service => node[:service],
                             :no_return_param => true,
                             :reference => ref}
          end
        end
      end
    end
    invalid_refs
  end
end
