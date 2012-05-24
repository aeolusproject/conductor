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

FactoryGirl.define do

  factory :session, :class => ActiveRecord::SessionStore::Session  do
    session_id 'ee73441902cb9445483e498cb05dc398'
    data 'BAh7CSIZd2FyZGVuLnVzZXIudXNlci5rZXlpFSIXamF2YXNjcmlwdF9lbmFi\nbGVkVCIQX2NzcmZfdG9rZW4iMVJWYkl2bjBoUEhZdi83aUpmU2FybFdQVWx0\nT0pvNHZOQXFkaXFaNURKRXc9IhBicmVhZGNydW1ic1sGewk6CmNsYXNzIg1j\nYXRhbG9nczoOdmlld3N0YXRlMDoJbmFtZSINQ2F0YWxvZ3M6CXBhdGgiDi9j\nYXRhbG9ncw==\n'
  end

end
