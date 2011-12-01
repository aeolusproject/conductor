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
