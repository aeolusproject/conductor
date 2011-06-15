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
