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

# Read config files
begin
  config = YAML.load_file("#{::Rails.root.to_s}/config/settings.yml")
rescue Errno::ENOENT
  raise "Failed to load #{::Rails.root.to_s}/config/settings.yml for aeolus-image-rubygem"
end

begin
  file = File.open("#{::Rails.root.to_s}/config/oauth.json", 'r') or raise "Could not open file"
  contents = file.read
  oauth_config = JSON.parse(contents)
rescue
  puts "Failed to load #{::Rails.root.to_s}/config/oauth.json, continuing without OAuth support. Run rake dc:oauth_keys and restart Conductor to enable."
end

# Aeolus::Image::Warehouse setup
begin
  Aeolus::Image::Warehouse::WarehouseModel.config = {
    :iwhd => {
      :url => config[:iwhd][:url],
      :oauth => {
        :consumer_key => (oauth_config['iwhd']['consumer_key'] rescue nil),
        :consumer_secret => (oauth_config['iwhd']['consumer_secret'] rescue nil)
      }
    }
  }
end

# Aeolus::Image::Factory setup
begin
  # Image Factory URL is required:
  factory_site = config[:imagefactory][:url] or
    raise "#{::Rails.root.to_s}/config/settings.yml failed to define Image Factory URL"

  # Consumer key and secret are not required; we fall back into OAuth-less mode:
  consumer_key    = oauth_config['factory']['consumer_key'] rescue nil
  consumer_secret = oauth_config['factory']['consumer_secret'] rescue nil
  factory_config = {}
  if consumer_key && consumer_secret
    factory_config = {
      :site => factory_site,
      :consumer_key => consumer_key,
      :consumer_secret => consumer_secret
    }
  else
    Rails.logger.warn "#{::Rails.root.to_s}/config/oauth.json did not define OAuth configuration for Image Factory; continuing without OAuth support"
    factory_config = {
      :site => factory_site
    }
  end
  Aeolus::Image::Factory::Base.config = factory_config
end
