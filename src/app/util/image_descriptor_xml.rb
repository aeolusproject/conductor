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

  def initialize(xmlstr = "")
    @doc = Nokogiri::XML(xmlstr)
    # create at least root node if it doesn't exist
    unless @doc.root
      @doc.root = Nokogiri::XML::Node.new('template', @doc)
    end
    @root = @doc.root.at_xpath('/template')
  end

  def name=(str)
    node = get_or_create_node('name')
    node.content = str
  end

  def name
    return get_node_text('name')
  end

  def description=(str)
    node = get_or_create_node('description')
    node.content = str
  end

  def description
    return get_node_text('description')
  end

  def platform
    node = @root.at_xpath('/template/os')
    return node ? node['name'] : nil
  end

  def platform=(platform_hash)
    # FIXME: we remove all repos because we don't know which one is for
    # platform
    # update: we don't add platform repo, image builder chooses right one from OS
    # name, but we add all other repos
    #recreate_repo_nodes
    platform_node = get_or_create_node('os')
    platform_node.xpath('.//*').remove
    platform_hash.each do |key, value|
      snode = Nokogiri::XML::Node.new(key, @doc)
      platform_node << snode
      snode.content = value
    end
    install_node = Nokogiri::XML::Node.new('install', @doc)
    install_node.set_attribute('type', 'url')
    platform_node << install_node
    url_node = Nokogiri::XML::Node.new('url', @doc)
    # TODO: change when more than one os is supported by conductor
    # url_node.content = "http://download.fedoraproject.org/pub/fedora/linux/releases/13/Fedora/x86_64/os/"
    url_node.content = YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_package_repositories.yml")['baseurl'] 
    install_node << url_node
  end

  def platform_version
    node = @root.at_xpath('/image/os/version')
    return node ? node.content : nil
  end

  def architecture
    node = @root.at_xpath('/template/os/arch')
    return node ? node.content : nil
  end

  def architecture=(str)
    get_or_create_node('os')['architecture'] = str
  end

  def services=(services)
    service_node = get_or_create_node('services')
    service_node.xpath('.//service').remove
    platform_hash.each do |key, value|
      snode = Nokogiri::XML::Node.new(key, @doc)
      platform_node << snode
      snode.content = value
    end
  end

  def services=(services)
    service_node = get_or_create_node('services')
    service_node.xpath('.//service').remove
    services.each do |s|
      snode = Nokogiri::XML::Node.new('service', @doc)
      service_node << snode
      snode.content = s[0]
    end
    @services = nil
  end

  def services
    unless @services
      @services = []
      @root.xpath('/template/services/service').each do |s|
        services << s.text
      end
    end
    return @services
  end

  def to_xml
    return @doc.to_xml
  end

  def packages
    @root.xpath('/template/packages/package').map do |s|
      s.at_xpath('.//name').text
    end
  end

  def groups
    @root.xpath('/template/groups/group').map do |s|
      s.at_xpath('.//name').text
    end
  end

  def add_package(pkg)
    pkgs_node = get_or_create_node('packages')
    add_package_node(pkgs_node, pkg) unless packages.include?(pkg)
  end

  def add_group(gname)
    # FIXME: this is temporary hack until we have new design:
    # when adding group, we add particular group packages
    # instead of whole group
    unless group = repository_manager.groups.find {|g| g[:id] == gname}
      raise "group #{gname} not found in repositories"
    end
    group[:packages].keys.each {|p| add_package(p)}
    #node = get_or_create_node('groups')
    #add_group_node(node, gname) unless groups.include?(gname)
  end

  def remove_package(package)
    @root.xpath('/template/packages/package').each do |s|
      if name = s.at_xpath('.//name') and name.text.to_s == package
        s.remove
      end
    end
  end

  def clear_packages
    @root.xpath('/template/packages').each { |s| s.remove }
  end

  def clear_groups
    @root.xpath('/template/groups').each { |s| s.remove }
  end

  private

  def add_group_node(parent, group)
    pnode = get_or_create_node('group', parent)
    n = Nokogiri::XML::Node.new('name', @doc)
    n.content = name
    pnode << n
  end

  def recreate_repo_nodes
    repo_node = get_or_create_node('repos')
    repo_node.xpath('.//repo').remove
    repository_manager.repositories.each do |repo|
      rnode = get_or_create_node('repo', repo_node)
      rnode.content = repo.yumurl
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
    node = @root.at_xpath('/template/' + path)
    return node ? node.text : nil
  end

  def add_package_node(parent, name)
    pnode = get_or_create_node('package', parent)
    n = Nokogiri::XML::Node.new('name', @doc)
    n.content = name
    pnode << n
  end

  def repository_manager
    @repository_manager ||= RepositoryManager.new
  end
end
