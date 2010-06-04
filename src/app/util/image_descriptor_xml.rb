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

class ImageDescriptorXML
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
    recreate_repo_nodes(str, services)

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
    repositories = repository_manager.repositories
    services.each do |s|
      snode = Nokogiri::XML::Node.new('service', @doc)
      service_node << snode
      snode.content = s[0]
      if repo = repositories[s[0]]
        add_service_packages(s[0], repo)
      end
    end
    recreate_repo_nodes(platform, services)
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

  def packages
    packages = {}
    @root.xpath('/image/packages/package').each do |s|
      group = s.at_xpath('.//group').text
      packages[group] ||= []
      packages[group] << {:name => s.at_xpath('.//name').text}
    end
    packages
  end

  def packages=(packages)
    pkgs_node = get_or_create_node('packages')
    pkgs_node.xpath('.//package').remove
    packages.each do |pkg|
      group, name = pkg.split(/#/, 2)
      add_package(pkgs_node, name, group)
    end
  end

  private

  def recreate_repo_nodes(platform, services)
    unless repconf = platforms[platform]
      raise "unknown platform #{platform}"
    end

    repo_node = get_or_create_node('repos')
    repo_node.xpath('.//repo').remove
    rnode = get_or_create_node('repo', repo_node)
    rnode.content = repconf['baseurl']

    repositories = repository_manager.repositories
    services.each do |s|
      if rep = repositories[s[0]]
        rnode = get_or_create_node('repo', repo_node)
        rnode.content = rep['baseurl']
      end
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

  def add_service_packages(repid, repconf)
    repo = repository_manager.get_repository(repid)
    packages = repo.get_packages
    pkgs_node = get_or_create_node('packages')
    pkgs_node.xpath('.//package').remove
    packages.each {|p| add_package(pkgs_node, p[:name], p[:group])}
  end

  def add_package(parent, name, group)
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
