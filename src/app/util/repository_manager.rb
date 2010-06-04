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
    def initialize(baseurl)
      @baseurl = baseurl
      @repomd_uri = File.join(@baseurl, 'repodata', 'repomd.xml')
      begin
        repoio = open(@repomd_uri)
      rescue
        raise "failed to download repomd file #{@repomd_uri}"
      end
      @repomd = Nokogiri::XML(repoio)
    end

    def get_packages
      packages = []
      # FIXME: currently are selected only mandatory and default packages,
      # optional packages are ingored
      get_packages_nodes.each do |node|
        name = node.at_xpath('./xmlns:name/child::text()')
        group = node.at_xpath('./xmlns:format/rpm:group/child::text()')
        description = node.at_xpath('./xmlns:description/child::text()')
        next unless name and group
        packages << {
          :name => name.text,
          :group => group.text,
          :description => description ? description.text : '',
        }
      end
      return packages
    end

    def get_packages_by_group
      groups = {}
      get_packages.each do |p|
        group = (groups[p[:group]] ||= [])
        group << p
      end
      return groups
    end

    private

    def get_packages_nodes
      unless @packages_nodes
        data = get_xml(get_primary_url)
        xml = Nokogiri::XML(data)
        @packages_nodes = xml.xpath('/xmlns:metadata/xmlns:package')
      end
      return @packages_nodes
    end

    def get_xml(url)
      xml_data = open(url)
      if url =~ /\.gz$/
        return Zlib::GzipReader.new(xml_data).read
      else
        return xml_data
      end
    end

    def get_primary_url
      location = @repomd.xpath('/xmlns:repomd/xmlns:data[@type="primary"]/xmlns:location').first
      raise "location for primary data not found" unless location
      return File.join(@baseurl, location['href'])
    end
  end

  def initialize
    @config = YAML.load_file("#{RAILS_ROOT}/config/image_descriptor_package_repositories.yml")
  end

  def get_repository(repository_id)
    repo = @config[repository_id]
    raise "Repository '#{repository_id}' doesn't exist" unless repo
    return CompsRepository.new(repo['baseurl'])
  end

  def repositories
    return @config
  end
end
