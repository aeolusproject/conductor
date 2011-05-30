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

require 'rest_client'
require 'nokogiri'

class PushJob < Struct.new(:provider_image_id, :hydra)
  def perform
    @logger = Delayed::Worker.logger
    @logger.info "--- start ---"
    @logger.info "PushJob for provider_image_id: #{provider_image_id}"
    provider_image = ProviderImage.find(provider_image_id)
    # TODO: what if a provider has multiple accounts
    # for now pick first account
    provider_account = provider_image.provider.provider_accounts.first
    cred_block = provider_account.build_credentials.to_xml.html_safe
    response = RestClient.post(YAML.load_file("#{RAILS_ROOT}/config/image_factory_console.yml")['pushurl'], :image_id => provider_image.image.uuid,
                      :provider => provider_image.provider.name,
                      :credentials => cred_block
                    )
    if response.code==200
      @logger.info "success "
      xml = Nokogiri::XML(response.body)
      @return_uuid = xml.xpath('//image/uuid').first.text
      provider_image.uuid = @return_uuid
      provider_image.save
      @logger.info "uuid: #{@return_uuid}"
    else
      @logger.error "failure"
      @logger.error response.body
      # TODO: raise an error and capture it somewhere
    end
    @return_uuid
  end
end
