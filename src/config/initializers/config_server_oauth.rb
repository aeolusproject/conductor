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

# The :config_server_oauth parameter is added in the config_server model object
# just before executing each request against a config server.
# This is a little scary, since this proc is added at the global RestClient
# scope.  The :config_server_oauth parameter should keep any other RestClient
# library users from having this block accidentally executed.
#
RestClient.add_before_execution_proc do |request, params|
  if params.key?(:config_server_oauth)
    consumer = OAuth::Consumer.new(
      params[:consumer_key],
      params[:consumer_secret],
      :site => params[:url]
    )
    access_token = OAuth::AccessToken.new(consumer)
    access_token.sign!(request)
  end
end
