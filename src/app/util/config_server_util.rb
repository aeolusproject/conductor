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

require 'uuidtools'
require 'nokogiri'
require 'rest_client'
require 'cgi'

module ConfigServerUtil
  class InstanceConfigError < RuntimeError; end

=begin
  Subclasses should use xml() to append XML text the XML string
=end
  class ToXML
    @num_spaces = 0

    def initialize
      @xml = ""
    end

    def to_xml(opts={})
      @num_spaces = opts[:indent] || 0
      _xml
      @xml
    end

    protected
    def pad
      @pad ||= @num_spaces.times.map {|x| " "}.join
    end

    def xml(str)
      @xml << "#{pad}#{str}"
    end

    def _xml
    end
  end

  class ParameterConfig < ToXML
    attr_accessor :name
    def initialize(name)
      super()
      @name = name
    end

    protected
    def _xml
      xml "<parameter name='#{@name}'>\n"
      if block_given?
        xml "  " + yield
      end
      xml "</parameter>\n"
    end
  end

  class ReferenceParameterConfig < ParameterConfig
    attr_accessor :assembly_name, :parameter_name
    def initialize(name, assembly_name, parameter_name)
      super(name)
      @assembly_name = assembly_name
      @parameter_name = parameter_name
    end

    protected
    def _xml
      super do
        "<reference assembly='#{@assembly_name}'" +
           " provided-parameter='#{@parameter_name}'/>\n"
      end
    end
  end

  class ValueParameterConfig < ParameterConfig
    attr_accessor :value
    def initialize(name, value)
      super(name)
      @value = value
    end

    protected
    def _xml
      super do
        "<value><![CDATA[#{@value}]]></value>\n"
      end
    end
  end

  class ServiceConfig < ToXML
    attr_accessor :parameters
    def initialize(svc)
      super()
      @svc = svc
      @parameters = []
    end

    def name
      @name ||= @svc.name
    end

    def executable
      @executable ||= if @svc.executable
        @svc.executable
      end
    end

    def files
      @files ||= if not @svc.files.empty?
        @svc.files
      else []; end
    end

    protected
    def _xml
      xml "<service name='#{@name}'>\n"
      if executable
        xml "  <executable url='#{executable}'/>\n"
      end
      unless files.empty?
        xml "  <files>\n"
        files.each do |file|
          xml "    <file url='#{file}'/>\n"
        end
        xml "  </files>\n"
      end
      unless @parameters.empty?
        xml "  <parameters>\n"
        xml(@parameters.map {|p| p.to_xml(:indent => @num_spaces + 2)}.join)
        xml "  </parameters>\n"
      end
      xml "</service>\n"
    end
  end

  class InstanceConfigXML < ToXML
    attr_reader :deployable_name, :deployable_id
    attr_reader :assembly_name, :assembly_type, :hwp
    attr_reader :hardware_profile, :realm, :uuid
    attr_reader :services, :provided_params

    def initialize(instance, assembly_uuids, config_values, deployable_id, deployable_name, config_server)
      super()
      @instance = instance
      @assembly = instance.assembly_xml
      @assembly_uuids = assembly_uuids
      @config_values = config_values || {}
      @deployable_id = deployable_id
      @deployable_name = deployable_name

      @config_server = config_server

      @uuid = @instance.uuid
    end

    def hardware_profile
      @assembly.hwd if @assembly
    end

    def to_s
      @config_xml ||= to_xml
    end

    protected
    def _xml
      xml "<instance-config id='#{@uuid}' name='#{@assembly.name}' secret='#{@instance.secret}'>\n"
      xml "  <deployable name='#{@deployable_name}' id='#{@deployable_id}'/>\n"
      xml "  <provided-parameters>\n"
      provided_parameters.map do |p|
        xml "    <provided-parameter name='#{p}'/>\n"
      end.join
      xml "  </provided-parameters>\n"
      xml "  <services>\n"
      xml(services.map {|s| s.to_xml(:indent => 4)}.join)
      xml "  </services>\n"
      xml "</instance-config>"
    end

    private
    def executable
      @executable ||= if @assembly.executable
        @assembly.executable
      end
    end

    def files
      @files ||= unless @assembly.files.empty?
        @assembly.files
      end
    end

    def provided_parameters
      @provided_parameters ||= unless @assembly.output_parameters.empty?
        @assembly.output_parameters.dup
      else
        []
      end
    end

    def services
      @services ||= @assembly.services.map do |svc|
        service = ServiceConfig.new(svc)
        vals = @config_values[service.name] || {}
        svc.parameters.each do |param|
          val = nil
          if vals[param.name]
            val = ValueParameterConfig.new(param.name, vals[param.name])
          elsif param.value
            val = ValueParameterConfig.new(param.name, param.value)
          elsif param.reference?
            assembly_uuid = @assembly_uuids[param.reference_assembly]
            val = ReferenceParameterConfig.new(param.name,
                      assembly_uuid, param.reference_parameter)
          else
            raise InstanceConfigError, "No value provided for parameter.  " +
              "Assembly: #{@assembly.name}, Service: #{service.name}, " +
              "Parameter: #{param.name}"
          end
          service.parameters << val
        end
        service
      end
    end
  end

  # Generates the instance configuration data for all the instances
  # in a deployable.  The instance configurations need to be generated together
  # in order to resolve inter-assembly dependent parameters.
  def self.instance_configs(deployment, instances, config_server)
    deployment_id = deployment.uuid
    deployable = deployment.deployable_xml
    # we need the list of assembly UUIDs before we start processing the
    # assemblies to help resolve cross assembly dependencies

    # need to have the list of instance UUIDs before processing the instance
    # configurations in order to resolve inter-assembly dependencies
    assembly_uuids = {}
    instances.each do |instance|
      assembly_uuids[instance.assembly_xml.name] = instance.uuid
      instance.secret = Instance.generate_oauth_secret
      instance.save!
    end
    instances.map do |instance|
      {instance.uuid => InstanceConfigXML.new(instance, assembly_uuids,
                                              nil, deployment_id, deployable.name,
                                              config_server)}
    end.compact.inject :merge
  end
end
