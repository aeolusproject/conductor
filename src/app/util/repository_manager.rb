#
# Copyright (C) 2009 Red Hat, Inc.
# Written by Jan Provaznik <jprovazn@redhat.com>
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

require 'yaml'
require 'util/repository_manager/comps_repository'
require 'util/repository_manager/pulp_repository'

class RepositoryManager
  attr_reader :repositories

  def initialize(opts = {})
    @config = opts[:config] || load_config
    @config = [ @config ] if Hash === @config
    @repositories = get_repositories
  end

  def all_groups(repository = nil)
    unless @all_groups
      @all_groups = {}
      repositories.each do |r|
        next if repository and repository != 'all' and repository != r.id
        r.groups.each do |group, data|
          if @all_groups[group]
            @all_groups[group][:packages].merge!(data[:packages])
          else
            @all_groups[group] = data
          end
        end
      end
    end
    return @all_groups
  end

  def packages(repository = nil)
  end

  def categories(repository = nil)
    unless @all_categories
      @all_categories = {}
      repositories.each do |r|
        next if repository and repository != 'all' and repository != r.id
        r.categories.each do |id, data|
          if @all_categories[id]
            @all_categories[id][:groups] += data[:groups]
          else
            @all_categories[id] = data
          end
        end
      end
    end
    return @all_categories
  end

  def packages(repository = nil)
    unless @packages
      @packages = []
      repositories.each do |r|
        next if repository and repository != 'all' and repository != r.id
        @packages += r.packages
      end
    end
    return @packages
  end

  # TODO: this is temporary solution for categorizing packages
  def metagroups
    unless @metagroups
      @metagroups = {}
      File.readlines('config/image_descriptor_package_metagroups.conf').each do |line|
        group, entries_str = line.chomp.split('=')
        next unless group and entries_str
        @metagroups[group] = entries_str.split(',')
      end
    end
    @metagroups
  end

  def metagroup_packages(category, repository = nil)
    res = {}
    groups = all_groups(repository)
    metagroups[category].to_a.each do |entry|
      cat, group = entry.split(';')
      next unless c = categories[cat] and c[:groups].include?(group) and groups[group]
      res[group] = {:packages => groups[group][:packages].keys}
    end
    res
  end

  def metagroup_packages_with_tagged_selected_packages(category, pkgs, repository = nil)
    mgroups = metagroup_packages(category, repository)
    mgroups.each_value do |group|
      missing = false
      group[:packages].each do |pkg|
        unless pkgs.find {|p| p[:name] == pkg}
          missing = true
          break
        end
      end
      next if missing
      group[:selected] = true
    end
    mgroups
  end

  def all_groups_with_tagged_selected_packages(pkgs, repository = nil)
    groups = all_groups(repository)
    groups.each_value do |group|
      pkgs.each do |pkg|
        next unless p = group[:packages][pkg[:name]]
        p[:selected] = true
      end
      group[:selected] = is_group_selected(group)
    end
    return groups
  end

  def repositories_hash
    res = {}
    @repositories.each do |r|
      res[r.id] = r
    end
    res
  end

  def search_package(str, repository = nil)
    packages(repository).select {|p| p =~ /#{Regexp.escape(str)}/i}
  end

  private

  # returns true if all non-optional packages are selected
  # (if there are only non-optional packages in the group,
  # all packages must be selected)
  def is_group_selected(group)
    all = true
    all_nonopt = true
    only_opt = true
    group[:packages].each_value do |pkg|
      all = false unless pkg[:selected]
      if pkg[:type] != 'optional'
        only_opt = false
        if !pkg[:selected]
          all_nonopt = false
        end
      end
    end
    return only_opt ? all : all_nonopt
  end

  def load_config
    YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_package_repositories.yml")
  end

  def get_repositories
    repositories = []
    @config.each do |rep|
      if rep['type'] == 'xml'
        repositories << CompsRepository.new(rep)
      elsif rep['type'] == 'pulp'
        repositories += PulpRepository.repositories(rep)
      end
    end
    return repositories
  end
end
