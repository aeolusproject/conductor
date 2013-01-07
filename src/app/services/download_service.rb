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

class DownloadService
  attr_reader :error

  def initialize(url)
    @url = url
  end

  def download
    begin
      download!
    rescue Exception => e
      @error = I18n.t('application_controller.flash.error.not_valid_or_reachable', :url => @url)
      nil
    end
  end

  def download!
    raise I18n.t('application_controller.flash.error.no_url_provided') if @url.blank?
    raise I18n.t('application_controller.flash.error.not_valid_url', :url => @url) unless @url =~ URI::regexp

    response = RestClient.get(@url, :accept => :xml)
    if response.code == 200
      return response
    else
      raise I18n.t('application_controller.flash.error.download_failed')
    end
  end
end
