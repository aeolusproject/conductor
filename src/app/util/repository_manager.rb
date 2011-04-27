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
    @selected_repositories = get_selected_repositories(opts[:repositories])
  end

  def groups
    @groups ||= @selected_repositories.map {|repo| repo.groups}.flatten
  end

  def packages
    @packages ||= @selected_repositories.map {|repo| repo.packages}.flatten
  end

  def categories
    @categories ||= @selected_repositories.map {|repo| repo.categories}.flatten
  end

  def repositories_hash
    res = {}
    @repositories.each do |r|
      res[r.id] = r
    end
    res
  end

  def search_package(str)
    @selected_repositories.map {|repo| repo.search_package(str)}.flatten
  end

  # TODO (remove): this is temporary solution for categorizing packages
  def metagroup_packages(category)
    res = []
    grps = groups
    metagroups[category].to_a.each do |entry|
      gname = entry[1]
      cat = categories.find{|t| t[:id] == entry[0]}
      group = grps.find{|g| g[:id] == gname}
      next unless cat and cat[:groups].include?(gname) and group
      next if res.find{|g| g[:name] == gname}
      res << {:label => group[:name], :name => gname, :packages => group[:packages].keys}
    end
    res
  end

  # TODO (remove): this is temporary solution for categorizing packages
  def metagroups
    unless @metagroups
      @metagroups = {}
      File.readlines('config/image_descriptor_package_metagroups.conf').each do |line|
        group, entries_str = line.chomp.split('=')
        next unless group and entries_str
        @metagroups[group] = entries_str.split(',').map {|entry| entry.split(';')}
      end
    end
    @metagroups
  end

  private

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

  def get_selected_repositories(repos)
    return @repositories if repos.blank?
    repos.map do |repo|
      @repositories.find_all {|r| r.platform_id == repo} or raise "repository '#{repo}' not found"
    end.flatten
    @repositories
  end
end
