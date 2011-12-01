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

describe CatalogEntry do
  it "should have a name of reasonable length" do
    catalog_entry = FactoryGirl.create :catalog_entry
    [nil, '', 'x'*1025].each do |invalid_name|
      catalog_entry.deployable.name = invalid_name
      catalog_entry.deployable.should_not be_valid
    end
    catalog_entry.deployable.name = 'x'*1024
    catalog_entry.deployable.should be_valid
  end

  it "should have unique name" do
    catalog = FactoryGirl.create :catalog
    catalog_entry = FactoryGirl.create :catalog_entry, :catalog => catalog
    deployable2 = Factory.build(:deployable, :name => catalog_entry.deployable.name)
    catalog_entry2 = Factory.build(:catalog_entry, :deployable => deployable2, :catalog => catalog)
    catalog_entry2.deployable.should_not be_valid

    catalog_entry2.deployable.name = 'unique name'
    catalog_entry2.deployable.should be_valid
  end

  it "should have xml content" do
    catalog_entry = FactoryGirl.create :catalog_entry
    catalog_entry.deployable.xml = ''
    catalog_entry.deployable.should_not be_valid
  end
end
