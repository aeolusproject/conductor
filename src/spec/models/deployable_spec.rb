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

describe Deployable do
  shared_examples_for "deployable XML with cyclic reference" do
    it "should not be valid" do
      @deployable.valid?.should be_false
    end

    it "should detect one cycle" do
      @cycles.length.should == 1
    end
  end

  it "should generate xml when set from image" do
    image = FactoryGirl.create(:base_image_with_template)
    hw_profile = FactoryGirl.build(:front_hwp1)
    deployable = FactoryGirl.build(:deployable)
    deployable.set_from_image(image, deployable.name, hw_profile)
    deployable.xml_filename.should eql(deployable.name)
    doc = Nokogiri::XML deployable.xml
    doc.at_xpath('/deployable')[:name].should eql(deployable.name)
    doc.at_xpath('/deployable/assemblies/assembly')[:hwp].should eql(hw_profile.name)
    doc.at_xpath('/deployable/assemblies/assembly')[:name].should eql(image.name)
    doc.at_xpath('/deployable/assemblies/assembly/image')[:id].should eql(image.uuid)
  end

  it "should not be valid if xml is not parsable" do
    deployable = FactoryGirl.build(:deployable)
    deployable.should be_valid
    deployable.xml = deployable.xml.clone << "</deployable>"
    deployable.should_not be_valid
  end

  it "should not be valid if xml has multiple assemblies with the same name" do
    deployable = FactoryGirl.build(:deployable_unique_name_violation)
    deployable.validate_deployable_xml
    deployable.errors[:xml].should == [I18n.t('catalog_entries.flash.warning.not_valid_duplicate_assembly_names')]
  end

  it "should have a name of reasonable length" do
    catalog = FactoryGirl.create :catalog
    deployable = FactoryGirl.create(:deployable, :catalogs => [catalog])
    [nil, '', 'x'*1025].each do |invalid_name|
      deployable.name = invalid_name
      deployable.should_not be_valid
    end
    deployable.name = 'x'*1024
    deployable.should be_valid
  end

  it "should have unique name" do
    catalog = FactoryGirl.create :catalog
    deployable = FactoryGirl.create :deployable, :catalogs => [catalog]
    deployable2 = Factory.build(:deployable, :name => deployable.name)
    deployable2.should_not be_valid

    deployable2.name = 'unique name'
    deployable2.should be_valid
  end

  it "should have xml content" do
    catalog = FactoryGirl.create :catalog
    deployable = FactoryGirl.create :deployable, :catalogs => [catalog]
    deployable.xml = ''
    deployable.should_not be_valid
  end

  describe "validation of deployable_xml with cyclic service references" do
    before :each do
      @deployable = FactoryGirl.build(:deployable_with_cyclic_service_references)
      @cycles = DeployableXML.new(@deployable.xml).dependency_graph.cycles
    end

    it_behaves_like "deployable XML with cyclic reference"

    it "should detect cycle between services of same assembly" do
      cycle = @cycles.first
      cycle.length.should == 2
      cycle.find {|n| n[:assembly] == 'assembly1' && n[:service] == 'service1'}
      cycle.find {|n| n[:assembly] == 'assembly1' && n[:service] == 'service2'}
    end
  end

  describe "validation of deployable_xml with not existing references" do
    before :each do
      @deployable = FactoryGirl.build(:deployable_with_not_existing_references)
      @invalid_refs = DeployableXML.new(@deployable.xml).
                        dependency_graph.not_existing_references
    end

    it "should not be valid" do
      @deployable.should_not be_valid
    end

    it "should detect reference to not existing assembly" do
      @invalid_refs.find {|r| r[:assembly] == 'assembly2' &&
        r[:service] == 'service1' &&
        r[:reference][:assembly] ==  'assembly3' &&
        r[:reference][:service] ==  'service1'}.should_not be_nil
    end

    it "should detect reference to not existing service" do
      @invalid_refs.find {|r| r[:assembly] == 'assembly1' &&
        r[:service] == 'service1' &&
        r[:reference][:assembly] ==  'assembly1' &&
        r[:reference][:service] ==  'service2'}.should_not be_nil
    end

    it "should detect reference to not existing parameter" do
      @invalid_refs.find {|r| r[:assembly] == 'assembly1' &&
        r[:service] == 'service1' &&
        r[:no_return_param] &&
        r[:reference][:assembly] ==  'assembly2' &&
        r[:reference][:param] ==  'param2'}.should_not be_nil
    end
  end

  it "should manage permissions on catalog changes" do
    pool1 = FactoryGirl.create :pool
    pool2 = FactoryGirl.create :pool
    catalog1 = FactoryGirl.create :catalog #, :pool => :pool1
    catalog2 = FactoryGirl.create :catalog
    catalog1.pool.should_not == catalog2.pool
    admin = FactoryGirl.create :admin_user
    pool1_perm = Permission.create(:entity => admin.entity,
                                   :role => Role.first(:conditions =>
                                                   ['name = ?', 'pool.admin']),
                                     :permission_object => catalog1.pool)
    pool2_perm = Permission.create(:entity => admin.entity,
                                   :role => Role.first(:conditions =>
                                        ['name = ?', 'pool.deployable.admin']),
                                     :permission_object => catalog2.pool)
    deployable = FactoryGirl.create :deployable, :catalogs => [catalog1]
    catalog1.reload
    catalog2.reload
    catalog1.pool.permissions.should == [pool1_perm]
    catalog2.pool.permissions.should == [pool2_perm]

    catalog1.derived_permissions.collect {|p|
      p.role.name}.should == ["pool.admin"]
    catalog2.derived_permissions.collect {|p|
      p.role.name}.should == ["pool.deployable.admin"]
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.admin").should be_true
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.deployable.admin").should be_false
    deployable.catalogs.should == [catalog1]

    deployable.catalogs << catalog2
    deployable.reload
    deployable.catalogs.should == [catalog1, catalog2]
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.admin").should be_true
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.deployable.admin").should be_true

    deployable.catalog_entries.where(:catalog_id => catalog1.id).first.destroy
    deployable.reload
    deployable.catalogs.should == [catalog2]
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.admin").should be_false
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.deployable.admin").should be_true

    catalog2.pool = catalog1.pool
    catalog2.save
    deployable.reload
    deployable.catalogs.should == [catalog2]
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.admin").should be_true
    deployable.derived_permissions.collect {|p|
      p.role.name}.include?("pool.deployable.admin").should be_false
  end
end
