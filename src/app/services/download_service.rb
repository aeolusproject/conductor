#
#   Copyright 2012 Red Hat, Inc.
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
      @error = _('XML file is either invalid or no longer reachable at %s') % @url
      nil
    end
  end

  def download!
    raise _('No URL is provided for XML import') if @url.blank?
    raise (_('Provided URL is not valid %s') % @url) unless @url =~ URI::regexp

    response = RestClient.get(@url, :accept => :xml)
    if response.code == 200
      return response
    else
      raise _('Download of XML file failed')
    end
  end
end
