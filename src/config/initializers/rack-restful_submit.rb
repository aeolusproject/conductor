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
