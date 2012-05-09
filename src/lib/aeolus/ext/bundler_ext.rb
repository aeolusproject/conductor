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

require "bundler"
module  Aeolus
  module Ext
    class BundlerExt
      def self.parse_from_gemfile(gemfile,*groups)
        ENV['BUNDLE_GEMFILE'] = gemfile
        groups.map! { |g| g.to_sym }
        groups = [:default] if groups.empty?
        g = Bundler::Dsl.evaluate(gemfile,'foo',true)
        list = []
        g.dependencies.each { |dep|
	  next unless ((groups & dep.groups).any? && dep.current_platform?)
	  Array(dep.autorequire || dep.name).each do |file|
            list << file
          end
        }
        list
      end
      def self.system_require(gemfile,*groups)
        BundlerExt.parse_from_gemfile(gemfile,*groups).each do |dep|
	  #This part ripped wholesale from lib/bundler/runtime.rb (github/master)
	  begin
	    require dep
          rescue LoadError => e
            if dep.include?('-')
              begin
                namespaced_file = dep.name.gsub('-', '/')
                require namespaced_file
              rescue LoadError
                raise if $1.gsub('-', '/') != namespaced_file
              end
            else
              BundlerExt.output.puts($1) if $1 != dep
            end
          end
        end
      end

      def self.output
        ENV['BUNDLER_STDERR'] || $stderr
      end
    end
  end
end
