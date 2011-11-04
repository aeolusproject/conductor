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

describe CatalogEntry do
  it "should have a name of reasonable length" do
    catalog_entry = FactoryGirl.create :catalog_entry
    [nil, '', 'x'*1025].each do |invalid_name|
      catalog_entry.name = invalid_name
      catalog_entry.should_not be_valid
    end
    catalog_entry.name = 'x'*1024
    catalog_entry.should be_valid
  end

  it "should have unique name" do
    catalog = FactoryGirl.create :catalog
    catalog_entry = FactoryGirl.create :catalog_entry, :catalog => catalog
    catalog_entry2 = Factory.build(:catalog_entry, :name => catalog_entry.name, :catalog => catalog)
    catalog_entry2.should_not be_valid

    catalog_entry2.name = 'unique name'
    catalog_entry2.should be_valid
  end

  it "should have a valid name across catalogs" do
    catalog1 = FactoryGirl.create :catalog
    catalog2 = FactoryGirl.create :catalog
    catalog_entry1 = FactoryGirl.create :catalog_entry, :name =>"same name", :catalog => catalog1
    catalog_entry2 = FactoryGirl.create :catalog_entry, :name => "same name", :catalog => catalog2
    catalog_entry1.should be_valid
    catalog_entry2.should be_valid
  end

  it "should have xml content" do
    catalog_entry = FactoryGirl.create :catalog_entry
    catalog_entry.xml = ''
    catalog_entry.should_not be_valid
  end

end
