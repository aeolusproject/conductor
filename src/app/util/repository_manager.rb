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

require 'open-uri'
require 'yaml'

class RepositoryManager
  class CompsRepository
    def initialize(baseurl, id)
      @id = id
      @baseurl = baseurl
    end

    def get_packages
      packages = []
      get_packages_nodes.each do |node|
        name = node.at_xpath('./xmlns:name/child::text()')
        group = node.at_xpath('./xmlns:format/rpm:group/child::text()')
        description = node.at_xpath('./xmlns:description/child::text()')
        next unless name and group
        packages << {
          :repository_id => @id,
          :name => name.text,
          :group => group.text,
          :description => description ? description.text : '',
        }
      end
      return packages
    end

    def get_groups
      groups = {}
      get_groups_nodes.each do |g|
        pkgs = get_group_packages(g)
        next if pkgs.empty?
        name = g.at_xpath('name').text
        groups[name] = {
          :name => name,
          :description => (t = g.at_xpath('description')) ? t.text : '',
          :packages => pkgs,
        }
      end
      return groups
    end

    def download_xml(type)
      begin
        url = get_url(type)
      rescue
        return ''
      end

      xml_data = open(url)
      if url =~ /\.gz$/
        return Zlib::GzipReader.new(xml_data).read
      else
        return xml_data.read
      end
    end

    private

    def get_xml(type)
      begin
        return File.open("#{RAILS_ROOT}/config/image_descriptor_xmls/#{@id}.#{type}.xml") { |f| f.read }
      rescue
        return download_xml(type)
      end
    end

    def get_group_packages(group_node)
      pkgs = {}
      group_node.xpath('packagelist/packagereq').each do |p|
        pkgs[p.text] = p.attr('type')
      end
      return pkgs
    end

    def get_packages_nodes
      unless @packages_nodes
        data = get_xml('primary')
        xml = Nokogiri::XML(data)
        @packages_nodes = xml.xpath('/xmlns:metadata/xmlns:package')
      end
      return @packages_nodes
    end

    def get_groups_nodes
      unless @groups_nodes
        data = get_xml('group')
        xml = Nokogiri::XML(data)
        @groups_nodes = xml.xpath('/comps/group')
      end
      return @groups_nodes
    end

    def get_url(type)
      if type == 'repomd'
        return File.join(@baseurl, 'repodata', 'repomd.xml')
      else
        location = repomd.xpath("/xmlns:repomd/xmlns:data[@type=\"#{type}\"]/xmlns:location").first
        raise "location for #{type} data not found" unless location
        return File.join(@baseurl, location['href'])
      end
    end

    def repomd
      unless @repomd
        @repomd = Nokogiri::XML(get_xml('repomd'))
      end
      return @repomd
    end
  end

  def initialize
    @config = YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_package_repositories.yml")
  end

  def get_repository(repository_id)
    repo = @config[repository_id]
    raise "Repository '#{repository_id}' doesn't exist" unless repo
    return CompsRepository.new(repo['baseurl'], repository_id)
  end

  def repositories
    return @config
  end

  def all_groups(repository = nil)
    unless @all_groups
      @all_groups = {}
      repositories.keys.each do |r|
        next if repository and repository != 'all' and repository != r
        get_repository(r).get_groups.each do |group, data|
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

  def all_packages(repository = nil)
    unless @all_packages
      @all_packages = []
      repositories.keys.each do |r|
        next if repository and repository != 'all' and repository != r
        @all_packages += get_repository(r).get_packages
      end
    end
    return @all_packages
  end
end
