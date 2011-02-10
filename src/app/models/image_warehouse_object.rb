#
# Copyright (C) 2010 Red Hat, Inc.
# Written by Scott Seago <sseago@redhat.com>
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
module ImageWarehouseObject

  WAREHOUSE_CONFIG = YAML.load_file("#{RAILS_ROOT}/config/image_warehouse.yml")

  def xml
    @xml ||= ImageDescriptorXML.new(self[:xml].to_s)
  end

  def upload
    self.uri = File.join(WAREHOUSE_CONFIG['baseurl'], "#{uuid}")
    response = Typhoeus::Request.put(self.uri, :body => xml.to_xml, :timeout => 30000)
    if response.code == 200
      update_attribute(:uploaded, true)
    else
      raise "failed to upload template (code #{response.code}): #{response.body}"
    end
  end

  def generate_uuid
    # TODO: generate real uuid here, e.g. with some ruby uuid generator
    self.uuid ||= "#{self.name}-#{Time.now.to_f.to_s}"
  end

end
