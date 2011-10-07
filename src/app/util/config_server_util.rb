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
      @executable ||= if @svc.config_tooling and @svc.config_tooling.executable
        @svc.config_tooling.executable
      end
    end

    def files
      @files ||= if @svc.config_tooling and not @svc.config_tooling.files.empty?
        @svc.config_tooling.files.map {|f| f.url}
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
          xml "    <file url='#{file.url}'/>\n"
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

    def initialize(assembly, assembly_uuids, config_values, deployable_id, deployable_name, config_server)
      super()
      @assembly = assembly
      @assembly_uuids = assembly_uuids
      @config_values = config_values || {}
      @deployable_id = deployable_id
      @deployable_name = deployable_name

      @config_server = config_server

      @uuid = @assembly_uuids[@assembly.name]
    end

    def hardware_profile
      @assembly.hwd if @assembly
    end

    def user_data(opts={})
      opts[:base_64] ||= true
      user_data = "#{@config_server.host}:#{@config_server.port}:#{@uuid}"
      if @config_server.password
        # if the config server requires a password, use "password" for this
        # guest
        user_data << ":password"
      end
      return (opts[:base_64]) ? [user_data].pack("m0").delete("\n") : user_data
    end

    def to_s
      to_xml
    end

    protected
    def _xml
      password = nil
      if @config_server and @config_server.password
        password = "password".crypt("NaCl")
      end
      xml "<instance-config id='#{@uuid}' name='#{@assembly.name}'"
      xml " password='#{password}'" if password
      xml ">\n  <deployable name='#{@deployable_name}' id='#{@deployable_id}'/>\n"
      if @assembly.config_tooling
        config_tooling = @assembly.config_tooling
        if config_tooling.executable
          xml "  <executable url='#{config_tooling.executable}'/>\n"
        end
        unless config_tooling.files.empty?
          xml "  <files>\n"
          config_tooling.files.map do |f|
            xml "    <file url='#{f.url}'/>\n"
          end.join
          xml "  </files>\n"
        end
      end
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
      @executable ||= if @assembly.config_tooling and @assembly.config_tooling.executable
        @assembly.config_tooling.executable
      end
    end

    def files
      @files ||= unless @assembly.config_tooling.nil? or @assembly.config_tooling.files.empty?
        @assembly.config_tooling.files.map {|f| f.url }
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
          elsif param.default
            val = ValueParameterConfig.new(param.name, param.default)
          elsif param.reference
            assembly_uuid = @assembly_uuids[param.reference.assembly]
            val = ReferenceParameterConfig.new(param.name,
                      assembly_uuid, param.reference.parameter)
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

  def self.instance_configs(deployable, config_values, config_server)
    deployable_id = UUIDTools::UUID.timestamp_create.to_s
    # we need the list of assembly UUIDs before we start processing the
    # assemblies to help resolve cross assembly dependencies
    assembly_uuids = deployable.assemblies.map do |assembly|
      {assembly.name => UUIDTools::UUID.timestamp_create.to_s}
    end.inject :merge
    deployable.assemblies.map do |assembly|
      if assembly.requires_config_server?
        values = config_values.nil? ? nil : config_values[assembly.name]
        {assembly.name => InstanceConfigXML.new(assembly, assembly_uuids,
                              values, deployable_id, deployable.name,
                              config_server)}
      end
    end.compact.inject :merge
  end
end
