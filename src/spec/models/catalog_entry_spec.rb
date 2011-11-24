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
