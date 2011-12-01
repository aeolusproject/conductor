#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

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
