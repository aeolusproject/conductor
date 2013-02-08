#
#   Copyright 2013 Red Hat, Inc.
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

module DeployableMatching

  class AssemblyInstancesBuilder

    attr_reader :assembly_instances
    attr_reader :errors

    def initialize(attributes)
      attributes.each do |name, value|
        instance_variable_set("@#{name}", value)
      end

      @assembly_instances = []
      @errors = []
    end

    def self.build_from_deployable(permission_session, user, pool, deployable_xml, frontend_realm = nil)
      builder = self.new(:pool => pool,
                         :deployable_xml => deployable_xml,
                         :frontend_realm => frontend_realm)
      builder.build_assembly_instances(permission_session, user)

      builder
    end

    def self.build_from_instances(pool, instances)
      builder = self.new(:pool => pool, :instances => instances)
      builder.import_existing_instances

      builder
    end

    def build_assembly_instances(permission_session, user)
      @assembly_instances = []

      deployable_errors = Validator.errors_for_deployable(@pool, user, @deployable_xml)
      if deployable_errors.any?
        @errors += deployable_errors
        return nil
      end

      @assembly_instances = @deployable_xml.assemblies.map do |assembly|
        build_assembly_instance(assembly, permission_session, user)
      end
    end

    def import_existing_instances
      @assembly_instances = []

      @instances.each do |instance|
        assembly = instance.assembly_xml
        attrs = { :frontend_realm => instance.frontend_realm,
                  :pool => instance.pool,
                  :image_uuid => instance.image_uuid,
                  :image_build_uuid => instance.image_build_uuid,
                  :owner => instance.owner,
                  :hardware_profile => instance.hardware_profile }

        assembly_instance = AssemblyInstance.new(assembly, attrs, nil, nil)
        matches_builder = AssemblyMatchesBuilder.build(assembly_instance, @pool.pool_family.provider_accounts, @frontend_realm, instance)

        if matches_builder.errors.any?
          @errors << matches_builder.errors
          return nil
        end

        assembly_instance.matches = matches_builder.assembly_matches
        @assembly_instances << assembly_instance
      end
    end

    private

    def build_assembly_instance(assembly, permission_session, user)
      assembly_hwp = HardwareProfile.find_allowed_frontend_hwp_by_name(permission_session, user, assembly.hwp)

      assembly_errors = Validator.errors_for_assembly(assembly, assembly_hwp)
      if assembly_errors.any?
        @errors += assembly_errors
        return nil
      end

      attrs = { :frontend_realm => @frontend_realm,
                :pool => @pool,
                :image_uuid => assembly.image_id,
                :image_build_uuid => assembly.image_build,
                :owner => user,
                :hardware_profile => assembly_hwp }

      service_parameters = []
      assembly.services.each do |service|
        service.parameters.each do |parameter|
          if !parameter.reference?
            service_parameters << { :service => service.name,
                                    :name => parameter.name,
                                    :type => parameter.type,
                                    :value => parameter.value }
          end
        end
      end

      assembly_instance = AssemblyInstance.new(assembly, attrs, service_parameters, nil)
      matches_builder = AssemblyMatchesBuilder.build(assembly_instance, @pool.pool_family.provider_accounts, @frontend_realm)

      if matches_builder.errors.any?
        @errors += matches_builder.errors
        return nil
      end

      assembly_instance.matches = matches_builder.assembly_matches

      assembly_instance
    end

  end

end
