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
require 'util/repository_manager'

class ImageDescriptorXML

  UNKNOWN_GROUP = 'Individual packages'

  # FIXME: temporary way to only add jboss until other
  # services are supported
  SERVICE_PACKAGE_GROUPS = {
    # FIXME: jboss service is disabled because we don't have public repo
    # which contains groups for jboss
    #'jboss' => 'JBoss Core Packages'
  }

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    # create at least root node if it doesn't exist
    unless @doc.root
      @doc.root = Nokogiri::XML::Node.new('image', @doc)
    end
    @root = @doc.root.at_xpath('/image')
  end

  def name=(str)
    node = get_or_create_node('name')
    node.content = str
  end

  def name
    return get_node_text('name')
  end

  def platform=(str)
    # FIXME: we remove all repos beacouse we don't know which one is for
    # platform
    recreate_repo_nodes(str)
    node = get_or_create_node('os')
    node.content = str
  end

  def platform
    return get_node_text('os')
  end

  def platforms
    unless @platforms
      @platforms = YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_platform_repositories.yml")
    end
    return @platforms
  end

  def description=(str)
    node = get_or_create_node('description')
    node.content = str
  end

  def description
    return get_node_text('description')
  end

  def services=(services)
    service_node = get_or_create_node('services')
    service_node.xpath('.//service').remove
    services.each do |s|
      snode = Nokogiri::XML::Node.new('service', @doc)
      service_node << snode
      snode.content = s[0]
      if group = SERVICE_PACKAGE_GROUPS[s[0]]
        add_group(group)
      end
    end
    @services = nil
  end

  def services
    unless @services
      @services = []
      @root.xpath('/image/services/service').each do |s|
        services << s.text
      end
    end
    return @services
  end

  def to_xml
    return @doc.to_xml
  end

  def packages_by_group
    groups = {}
    @root.xpath('/image/groups/group').each do |g|
      groups[g.text] = []
    end
    @root.xpath('/image/packages/package').each do |s|
      name = s.at_xpath('.//group').text
      group = (groups[name] || groups[UNKNOWN_GROUP] ||= [])
      group << {:name => s.at_xpath('.//name').text}
    end
    return groups
  end

  def all_packages_by_group
    groups = {}
    all_groups = repository_manager.all_groups
    packages_by_group.each do |group, pkgs|
      if group_all = all_groups[group]
        groups[group] ||= []
        group_all[:packages].keys.sort.each do |pkg|
          groups[group] << {:name => pkg, :checked => pkgs.find {|p| p[:name] == pkg} ? true : false}
        end
      else
        groups[UNKNOWN_GROUP] ||= []
        groups[UNKNOWN_GROUP] += pkgs.map {|pkg| {:name => pkg[:name], :checked => true}}
      end
    end

    unknown_group = groups.delete(UNKNOWN_GROUP)
    sorted = groups.keys.sort.map do |group|
      {:name => group, :pkgs => groups[group]}
    end
    if unknown_group
      sorted << {:name => UNKNOWN_GROUP, :pkgs => unknown_group}
    end

    return sorted
  end

  def packages
    packages = []
    @root.xpath('/image/packages/package').each do |s|
      packages << {:name => s.at_xpath('.//name').text, :group => s.at_xpath('.//group').text}
    end
    return packages
  end

  def packages=(packages)
    pkgs_node = get_or_create_node('packages')
    pkgs_node.xpath('.//package').remove
    packages.uniq.each do |pkg|
      group, name = pkg.split(/#/, 2)
      add_package_node(pkgs_node, name, group)
    end
  end

  def add_package(pkg, group)
    group ||= UNKNOWN_GROUP
    pkgs_node = get_or_create_node('packages')
    unless older = packages.find {|p| p[:name] == pkg and p[:group] == group}
      add_package_node(pkgs_node, pkg, group)
    end
  end

  def add_group(gname)
    unless group = repository_manager.all_groups[gname]
      raise "group #{gname} not found in repositories"
    end
    groups = packages_by_group
    unless groups[gname]
      groups_node = get_or_create_node('groups')
      add_group_node(groups_node, gname)
    end
    group[:packages].each do |p, type|
      next if type == 'optional'
      add_package(p, group[:name])
    end
  end

  def remove_group(group)
    groups = packages_by_group
    groups.delete(group)
    pkgs_node = get_or_create_node('packages')
    pkgs_node.xpath('.//package').remove
    groups_node = get_or_create_node('groups')
    groups_node.xpath('.//group').remove
    groups.each do |group, pkgs|
      pkgs.each { |pkg| add_package_node(pkgs_node, pkg[:name], group) }
      add_group_node(groups_node, group)
    end
  end

  private

  def add_group_node(parent, group)
    n = Nokogiri::XML::Node.new('group', @doc)
    n.content = group
    parent << n
  end

  def recreate_repo_nodes(platform)
    unless repconf = platforms[platform]
      raise "unknown platform #{platform}"
    end

    repo_node = get_or_create_node('repos')
    repo_node.xpath('.//repo').remove
    rnode = get_or_create_node('repo', repo_node)
    rnode.content = repconf['baseurl']

    repository_manager.repositories.each do |rname, repo|
      rnode = get_or_create_node('repo', repo_node)
      rnode.content = repo['baseurl']
    end
  end

  def get_or_create_node(name, parent = @root)
    unless node = @root.at_xpath(name)
      node = Nokogiri::XML::Node.new(name, @doc)
      parent << node
    end
    return node
  end

  def get_node_text(path)
    node = @root.at_xpath('/image/' + path)
    return node ? node.text : nil
  end

  def add_package_node(parent, name, group)
    pnode = get_or_create_node('package', parent)
    n = Nokogiri::XML::Node.new('name', @doc)
    n.content = name
    pnode << n
    n = Nokogiri::XML::Node.new('group', @doc)
    n.content = group
    pnode << n
  end

  def repository_manager
    unless @repository_manager
      @repository_manager = RepositoryManager.new
    end
    return @repository_manager
  end
end
