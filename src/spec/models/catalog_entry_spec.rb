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
    catalog_entry = FactoryGirl.create :catalog_entry
    catalog_entry2 = Factory.build(:catalog_entry, :name => catalog_entry.name)
    catalog_entry2.should_not be_valid

    catalog_entry2.name = 'unique name'
    catalog_entry2.should be_valid
  end

  it "should have a url" do
    catalog_entry = FactoryGirl.create :catalog_entry
    catalog_entry.url = ''
    catalog_entry.should_not be_valid
  end

end
