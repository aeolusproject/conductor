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
