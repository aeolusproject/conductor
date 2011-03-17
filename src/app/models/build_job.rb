#
# Copyright (C) 2011 Red Hat, Inc.
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

require 'typhoeus'
require 'nokogiri'

class BuildJob < Struct.new(:image_id, :hydra)
  def perform
    @hydra = hydra
    @logger = Delayed::Worker.logger
    @logger.info "--- start ---"
    @logger.info "BuildJob for image_id: #{image_id}"
    begin
      if (@hydra == nil)
        @hydra = Typhoeus::Hydra.new
      end
      image = Image.find(image_id)
      request = Typhoeus::Request.new(YAML.load_file("#{RAILS_ROOT}/config/image_factory_console.yml")['buildurl'],
                                      :method => :post,
                                      :timeout => 60*1000, # in milliseconds
                                      :params => {
                                        :template => image.template.warehouse_url,
                                        :target => image.provider_type.codename})
      request.on_complete do |response|
        if response.success?
          @logger.info "success "
          xml = Nokogiri::XML(response.body)
          @return_uuid = xml.xpath('//image/uuid').first.text
          image.uuid = @return_uuid
          image.save
          @logger.info "uuid: #{@return_uuid}"
        else
          return_uuid = nil
          @logger.error "failure"
          @logger.error response.body
        end
      end
      @hydra.queue(request)
      @hydra.run
    rescue Exception => e
      @logger.error "Exception: "
      @logger.error e
    end
    @logger.info "--- done ---"
    @return_uuid
  end
end
