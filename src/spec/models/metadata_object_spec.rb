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

require 'spec_helper'

describe MetadataObject do

  before(:each) do
    @default_pool_family_metadata = MetadataObject.find_by_key("default_pool_family")
  end

  it "lookup on nonexistent key should return nil" do
    MetadataObject.lookup("can't find me").should be_nil
  end

  it "should require a valid key" do
    [nil, ""].each do |invalid_value|
      @default_pool_family_metadata.key = invalid_value
      @default_pool_family_metadata.should_not be_valid
    end
  end

  it "default pool family should return valid pool family" do
    MetadataObject.lookup("default_pool_family").should be_a(PoolFamily)
  end

  it "setting string value should work" do
    MetadataObject.set("test_string", "stringval")
    MetadataObject.lookup("test_string").should == "stringval"
  end

  it "setting activerecord object value should work" do
    MetadataObject.set("test_obj", FactoryGirl.create(:pool))
    MetadataObject.lookup("test_obj").should be_a(Pool)
  end

end
