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
