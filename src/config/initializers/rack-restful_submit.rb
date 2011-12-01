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

module Rack
  class RestfulSubmit
    def rewrite_request(env, prefixed_uri)
      # rails 3 expects that relative_url_root is not part of
      # requested uri, this fix also expects that mapping['url']
      # contains only path (not full url)
      uri = prefixed_uri.sub(/^#{Regexp.escape(env['SCRIPT_NAME'].to_s)}\//, '/')

      env['REQUEST_URI'] = uri
      if q_index = uri.index('?')
        env['PATH_INFO'] = uri[0..q_index-1]
        env['QUERYSTRING'] = uri[q_index+1..uri.size-1]
      else
        env['PATH_INFO'] = uri
        env['QUERYSTRING'] = ''
      end
    end
  end
end
