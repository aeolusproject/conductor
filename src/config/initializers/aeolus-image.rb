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

begin
  config = YAML.load_file("#{::Rails.root.to_s}/config/settings.yml")
rescue Errno::ENOENT
  raise "Failed to load #{::Rails.root.to_s}/config/settings.yml for aeolus-image-rubygem"
end

# Aeolus::Image::Warehouse takes our whole YAML config file:
begin
  Aeolus::Image::Warehouse::WarehouseModel.config = config
rescue NoMethodError
  raise "aeolus-image-rubygem is too old to support Warehouse configuration"
end

# Aeolus::Image::Factory has a more dignified configuration setting:
begin
  # Image Factory URL is required:
  factory_site = config[:imagefactory][:url] or
    raise "#{::Rails.root.to_s}/config/settings.yml failed to define Image Factory URL"

  # Consumer key and secret are not required; we fall back into OAuth-less mode:
  consumer_key    = config[:imagefactory][:oauth][:consumer_key] rescue nil
  consumer_secret = config[:imagefactory][:oauth][:consumer_secret] rescue nil
  factory_config = {}
  if consumer_key && consumer_secret
    factory_config = {
      :site => factory_site,
      :consumer_key => consumer_key,
      :consumer_secret => consumer_secret
    }
  else
    Rails.logger.warn "#{::Rails.root.to_s}/config/settings.yml did not define OAuth configuration for Image Factory; continuing without OAuth support"
    factory_config = {
      :site => factory_site
    }
  end
  Aeolus::Image::Factory::Base.config = factory_config
rescue NoMethodError
  raise "aeolus-image-rubygem is too old to support Image Factory configuration"
end
