class Heat

  class NotFoundError < StandardError
  end

  class NoConnectionError < StandardError
  end

  class << self

    def heat_request(connection, method, url, params, body)
      raise NoConnectionError unless connection

      method = method.to_s.downcase
      raise 'invalid method' unless ['get','put', 'post', 'delete'].include? method
      method = method.to_sym

      key = [method, url, params]
      if Rails.cache.exist? key, :namespace => 'heat'
          response, request, result = Rails.cache.read(key, :namespace => 'heat')
          yield response, request, result
          return
      end

      request_hash = {
        :method => method,
        :url => url,
        :headers => {
          :content_type => :json,
          :accept => :json,
          :'x-auth-user' => connection[:username],
          :'x-auth-key' => connection[:password],
          :'x-auth-url' => connection[:deltacloud_url],
          :'x-roles' => '',
          :params => params,
        },
      }
      request_hash[:payload] = body.to_json if body.present?

      RestClient::Request::execute(request_hash) do |response, request, result, &block|
        if [:head, :get].include?(method) and [301, 302, 307].include?(response.code)
          response.follow_redirection(request, result, &block)
        else
          if method == :get
            Rails.cache.write(key, [response, request, result],
              :namespace => 'heat',
              :expires_in => 10.seconds,
              :race_condition_ttl => 1.second)
          end
          yield response, request, result
        end
      end
    end

    def heat_url(connection, path='')
      return nil unless connection

      api_url = URI.join(connection[:heat_api], "/v1/#{connection[:tenant_id]}")
      File.join(api_url.to_s, path)
    end

    def create_stack(connection, name, template, instance_matches)
      parameters = {}
      instance_matches.each do |match|
        instance_name = match.instance.assembly_xml.name
        parameters["#{instance_name}_image"] = match.provider_image
        parameters["#{instance_name}_hardware_profile"] = match.hardware_profile.name
        parameters["#{instance_name}_key_name"] = match.instance.instance_key.name
      end

      body = {
        'stack_name' => name,
        'template' => template,
        'parameters' => parameters,
      }

      heat_request(connection, :post, heat_url(connection, '/stacks'), nil, body) do
        |response, request, result, &block|
        response.return!(request, result, &block) unless response.code == 201
      end

    end

    def list_stacks(connection)
      heat_request(connection, :get, heat_url(connection, '/stacks'), nil, nil) do
        |response, request, result, &block|
        case response.code
        when 200
          return JSON::load(response)['stacks']
        when 404
          raise NotFoundError
        else
          response.return!(request, result, &block)
        end
      end
    end

    def get_stack(connection, stack_name)
      heat_request(connection, :get, heat_url(connection, "/stacks/#{stack_name}"), nil, nil) do
        |response, request, result, &block|
        case response.code
        when 200
          return JSON::load(response)["stack"]
        when 404
          raise NotFoundError
        else
          response.return!(request, result, &block)
        end
      end
    end

    def list_resources(connection, stack_url)
      resources_url = URI.join(stack_url + '/', 'resources').to_s
      heat_request(connection, :get, resources_url, nil, nil) do
        |response, request, result, &block|
        case response.code
        when 200
          return JSON::load(response)
        when 404
          raise NotFoundError
        else
          response.return!(request, result, &block)
        end
      end
    end

  end
end
