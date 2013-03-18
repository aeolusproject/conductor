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

shared_examples_for 'http' do |code|
  http_codes = {
    'OK'                    => 200,
    'Created'               => 201,
    'No Content'            => 204,
    'Bad Request'           => 400,
    'Forbidden'             => 403,
    'Not Found'             => 404,
    'Unprocessable Entity'  => 422,
    'Internal Server Error' => 500,
  }
  code = http_codes[code] unless code.kind_of?(Fixnum)

  context "response status code" do
    subject { response.status }
    it { should == code }
  end
end

shared_examples_for "responding with XML" do
  context "response" do
    subject { response }

    it { should have_content_type("application/xml") }

    context "body" do
      subject { response.body }
      it { should be_xml }
    end
  end
end
