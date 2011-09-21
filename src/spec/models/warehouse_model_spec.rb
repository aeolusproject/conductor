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

describe WarehouseModel do

  describe "==" do
    it "should be true for cloned object" do
      image1 = Image.new({:uuid => '123', :foo => 'bar'})
      image2 = image1.dup
      image1.should == image2
    end

    it "should be true for two identical lookups" do
      image1 = Image.first
      image2 = Image.first
      image1.should == image2
    end

    it "should be false for a changed object" do
      image1 = Image.new({:uuid => '123', :foo => 'bar'})
      image2 = image1.dup
      image2.foo = 'baz'
      image1.should_not == image2
    end

    it "should be false for objects with a different number of attributes" do
      image1 = Image.new({:uuid => '123', :foo => 'bar'})
      image2 = Image.new({:uuid => '123'})
      image1.should_not == image2
      image2.should_not == image1
    end

  end

end
