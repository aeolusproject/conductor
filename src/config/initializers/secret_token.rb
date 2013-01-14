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

begin
  token = IO.read('/etc/aeolus-conductor/secret_token')
  raise RuntimeError, 'Secret token size is too small' if token.length < 30
  Conductor::Application.config.secret_token = token.chomp
rescue Exception => e
  # If anything goes wrong we make sure that the token is random.
  # This is safe even when Conductor is not configured correctly.
  # But session will be lost after each restart.
  Rails.logger.warn "Using randomly generated secret token: #{e.message}"
  Conductor::Application.config.secret_token = SecureRandom.hex(80)
end
