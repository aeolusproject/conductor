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

shared_examples_for "http OK" do
  context "response status code" do
    subject { response.status }
    it { should be_eql(200) }
  end
end

shared_examples_for "http Created" do
  context "response status code" do
    subject { response.status }
    it { should be_eql(201) }
  end
end

shared_examples_for "http No Content" do
  context "response status code" do
    subject { response.status }
    it { should be_eql(204) }
  end
end

shared_examples_for "http Bad Request" do
  context "response status code" do
    subject { response.status }
    it { should be_eql(400) }
  end
end

shared_examples_for "http Not Found" do
  context "response status code" do
    subject { response.status }
    it { should be_eql(404) }
  end
end

shared_examples_for "http Unprocessable Entity" do
  context "response status code" do
    subject { response.status }
    it { should be_eql(422) }
  end
end

shared_examples_for "http Internal Server Error" do
  context "response status code" do
    subject { response.status }
    it { should be_eql(500) }
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
