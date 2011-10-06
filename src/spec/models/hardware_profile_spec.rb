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

describe HardwareProfile do
  before(:each) do
    @hp = Factory.create(:mock_hwp1)
  end

  it "should create a new hardware profile" do
    @hp.should be_valid
  end

  it "should not validate for missing name" do
    [nil, ""].each do |value|
      @hp.name = value
      @hp.should_not be_valid
    end

    @hp.name = 'valid name'
    @hp.should be_valid
  end

  it "should require unique names" do
    hp2 = Factory.create(:mock_hwp2)
    @hp.should be_valid
    hp2.should be_valid

    hp2.name = @hp.name
    hp2.should_not be_valid
  end

  it "should require valid amount of memory" do
    ["hello", -1].each do |fail_value|
      @hp.memory.value = fail_value
      @hp.should_not be_valid
    end
  end

  it "should require valid amount of storage" do
    ["hello", -1].each do |fail_value|
      @hp.storage.value = fail_value
      @hp.should_not be_valid
    end
  end

  it "should require valid amount of CPU" do
    ["hello", -1].each do |fail_value|
      @hp.cpu.value = fail_value
      @hp.should_not be_valid
    end
  end

  it "should accept nil values" do
    @hp.cpu.value = nil
    @hp.memory.value = nil
    @hp.storage.value = nil
    @hp.should be_valid
  end

  it "should allow numerical amount of CPU" do
    [2, 2.2].each do |fail_value|
      @hp.cpu.value = fail_value
      @hp.should be_valid
    end
  end

  it "should have 'kind' attribute of hardware profile property set to string (not symbol)" do
    api_prop = mock('DeltaCloud::HWP::FloatProperty', :unit => 'MB', :name => 'memory', :kind => :fixed, :value => 12288.0)
    @hp.memory =@hp.new_property(api_prop)
    @hp.memory.kind.should equal(@hp.memory.kind.to_s)
  end

  it "should match the correct back end hardware profile for a given provider" do
    provider = FactoryGirl.create :mock_provider

    front_end_memory = FactoryGirl.create(:hwpp_fixed, :name => 'memory', :unit => 'MB', :value => '2048')
    front_end_storage = FactoryGirl.create(:hwpp_fixed, :name => 'storage', :unit => 'GB', :value => '850')
    front_end_cpu = FactoryGirl.create(:hwpp_fixed, :name => 'cpu', :unit => 'count', :value => '2')
    front_end_architecture = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    back_end_memory1 = create_hwpp_enum(['1024', '2048', '4048'], {:name => 'memory', :unit => 'MB', :value => '4048'})
    back_end_storage1 = create_hwpp_enum(['500', '1500', '2000'], {:name => 'storage', :unit => 'GB', :value => '1500'})
    back_end_cpu1 = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '1', :range_last => '4')
    back_end_architecture1 = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    back_end_memory2 = FactoryGirl.create(:hwpp_range, :name => 'memory', :unit => 'MB', :value => '4048', :range_first => '1024', :range_last => '8192')
    back_end_storage2 = create_hwpp_enum(['1500', '2000', '2500'], {:name => 'storage', :unit => 'GB', :value => '1500'})
    back_end_cpu2 = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '1', :range_last => '8')
    back_end_architecture2 = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    back_end_memory3 = FactoryGirl.create(:hwpp_range, :name => 'memory', :unit => 'MB', :value => '4048', :range_first => '1024', :range_last => '16384')
    back_end_storage3 = create_hwpp_enum(['2000', '2500', '3000'], {:name => 'storage', :unit => 'GB', :value => '2000'})
    back_end_cpu3 = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '1', :range_last => '16')
    back_end_architecture3 = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    front_end_hardware_profile = FactoryGirl.create(:hardware_profile, :memory => front_end_memory,
                                                            :cpu => front_end_cpu,
                                                            :storage => front_end_storage,
                                                            :architecture => front_end_architecture)

    back_end_hardware_profile1 = FactoryGirl.create(:hardware_profile, :memory => back_end_memory1,
                                                            :cpu => back_end_cpu1,
                                                            :storage => back_end_storage1,
                                                            :architecture => back_end_architecture1)

    back_end_hardware_profile2 = FactoryGirl.create(:hardware_profile, :memory => back_end_memory2,
                                                            :cpu => back_end_cpu2,
                                                            :storage => back_end_storage2,
                                                            :architecture => back_end_architecture2)

    back_end_hardware_profile3 = FactoryGirl.create(:hardware_profile, :memory => back_end_memory3,
                                                            :cpu => back_end_cpu3,
                                                            :storage => back_end_storage3,
                                                            :architecture => back_end_architecture3)

    provider.hardware_profiles << [back_end_hardware_profile1, back_end_hardware_profile2, back_end_hardware_profile3]

    HardwareProfile.match_provider_hardware_profile(provider, front_end_hardware_profile).should == back_end_hardware_profile1
  end

  it "should generate the correct override property values for a given property" do
    front_end_memory = FactoryGirl.create(:hwpp_fixed, :name => 'memory', :unit => 'MB', :value => '2048')
    front_end_storage = FactoryGirl.create(:hwpp_fixed, :name => 'storage', :unit => 'GB', :value => '850')
    front_end_cpu = FactoryGirl.create(:hwpp_fixed, :name => 'cpu', :unit => 'count', :value => '2')
    front_end_architecture = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    back_end_memory = FactoryGirl.create(:hwpp_range, :name => 'memory', :unit => 'MB', :value => '4048', :range_first => '1024', :range_last => '4048')
    back_end_storage = create_hwpp_enum(['500', '1500', '2000'], {:name => 'storage', :unit => 'GB', :value => '1500'})
    back_end_cpu = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '1', :range_last => '8')
    back_end_architecture = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    HardwareProfile.generate_override_property_value(front_end_memory, back_end_memory).should == 2048
    HardwareProfile.generate_override_property_value(front_end_storage, back_end_storage).should == '1500'
    HardwareProfile.generate_override_property_value(front_end_cpu, back_end_cpu).should == 2
  end

  it "should correctly match a front end hardware profile with a back end hardware profile" do
    front_end_memory = FactoryGirl.create(:hwpp_fixed, :name => 'memory', :unit => 'MB', :value => '2048')
    front_end_storage = FactoryGirl.create(:hwpp_fixed, :name => 'storage', :unit => 'GB', :value => '850')
    front_end_cpu = FactoryGirl.create(:hwpp_fixed, :name => 'cpu', :unit => 'count', :value => '2')
    front_end_architecture = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    back_end_memory_match = FactoryGirl.create(:hwpp_range, :name => 'memory', :unit => 'MB', :value => '4048', :range_first => '1024', :range_last => '4048')
    back_end_storage_match = create_hwpp_enum(['850', '1500', '2000'], {:name => 'storage', :unit => 'GB', :value => '1500'})
    back_end_cpu_match = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '1', :range_last => '8')
    back_end_architecture_match = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    back_end_memory_fail = FactoryGirl.create(:hwpp_range, :name => 'memory', :unit => 'MB', :value => '1024', :range_first => '512', :range_last => '1024')
    back_end_storage_fail = create_hwpp_enum(['1000', '1500', '2000'], {:name => 'storage', :unit => 'GB', :value => '1500'})
    back_end_cpu_fail = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '4', :range_last => '8')
    back_end_architecture_fail = FactoryGirl.create(:hwpp_fixed, :name => 'architecture', :unit => 'label', :value => 'x86_64')

    front_end_hardware_profile = FactoryGirl.create(:hardware_profile, :memory => front_end_memory,
                                                            :cpu => front_end_cpu,
                                                            :storage => front_end_storage,
                                                            :architecture => front_end_architecture)

    back_end_hardware_profile_match = FactoryGirl.create(:hardware_profile, :memory => back_end_memory_match,
                                                                 :cpu => back_end_cpu_match,
                                                                 :storage => back_end_storage_match,
                                                                 :architecture => back_end_architecture_match)

    back_end_hardware_profile_fail = FactoryGirl.create(:hardware_profile, :memory => back_end_memory_fail,
                                                                :cpu => back_end_cpu_fail,
                                                                :storage => back_end_storage_fail,
                                                                :architecture => back_end_architecture_fail)

    HardwareProfile.match_hardware_profile(front_end_hardware_profile, back_end_hardware_profile_match).should == true
    HardwareProfile.match_hardware_profile(front_end_hardware_profile, back_end_hardware_profile_fail).should == false
  end

  it "should correctly match front end hardware profile properties with back end hardware profile properties" do
    front_end_memory = FactoryGirl.create(:hwpp_fixed, :name => 'memory', :unit => 'MB', :value => '2048')
    front_end_storage = FactoryGirl.create(:hwpp_fixed, :name => 'storage', :unit => 'GB', :value => '850')
    front_end_cpu = FactoryGirl.create(:hwpp_fixed, :name => 'cpu', :unit => 'count', :value => '3')

    back_end_memory_match = FactoryGirl.create(:hwpp_range, :name => 'memory', :unit => 'MB', :value => '4048', :range_first => '1024', :range_last => '4048')
    back_end_storage_match = create_hwpp_enum(['850', '1500', '2000'], {:name => 'storage', :unit => 'GB', :value => '1500'})
    back_end_cpu_match = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '1', :range_last => '8')

    back_end_memory_fail = FactoryGirl.create(:hwpp_range, :name => 'memory', :unit => 'MB', :value => '512', :range_first => '512', :range_last => '1024')
    back_end_storage_fail = create_hwpp_enum(['250', '500', '750'], {:name => 'storage', :unit => 'GB', :value => '500'})
    back_end_cpu_fail = FactoryGirl.create(:hwpp_range, :name => 'cpu', :unit => 'count', :value => '4', :range_first => '1', :range_last => '2')

    HardwareProfile.match_hardware_profile_property(front_end_memory, back_end_memory_match).should == true
    HardwareProfile.match_hardware_profile_property(front_end_storage, back_end_storage_match).should == true
    HardwareProfile.match_hardware_profile_property(front_end_cpu, back_end_cpu_match).should == true

    HardwareProfile.match_hardware_profile_property(front_end_memory, back_end_memory_fail).should == false
    HardwareProfile.match_hardware_profile_property(front_end_storage, back_end_storage_fail).should == false
    HardwareProfile.match_hardware_profile_property(front_end_cpu, back_end_cpu_fail).should == false
  end

  it "should handle nils in ranged values in generate_override_property_values" do
    fe_hwp = Factory.create(:front_end_nil_cpu)
    be_hwp = Factory.create(:back_hwp_ranged_cpu)
    overrides = HardwareProfile.generate_override_property_values(fe_hwp, be_hwp)
    overrides[:cpu].should_not be_blank
  end


  it "should handle nils in enum values in generate_override_property_values" do
    p = create_hwpp_enum(['500', '1500', '2000'], {:name => 'storage', :unit => 'GB', :value => '1500'})
    fe_hwp = Factory.create(:front_end_nil_storage)
    be_hwp = Factory.create(:mock_hwp2, :storage => p)
    overrides = HardwareProfile.generate_override_property_values(fe_hwp, be_hwp)
    overrides[:storage].should_not be_blank
  end

  it "should return an integer for ranged values" do
    fe_hwp = Factory.create(:front_end_with_floats)
    be_hwp = Factory.create(:back_hwp_ranged_cpu)
    overrides = HardwareProfile.generate_override_property_values(fe_hwp, be_hwp)
    overrides[:cpu].is_a?(Integer).should be_true
  end



  def create_hwpp_enum(value_array, properties = {})
    hwpp_enum = FactoryGirl.create(:hwpp_enum, properties)
    value_array.each do |value|
      hwpp_enum.property_enum_entries << FactoryGirl.create(:property_enum_entry, :value => value, :hardware_profile_property => hwpp_enum)
    end
    return hwpp_enum
  end

  def check_enum_entries_match(hwpp, value_array)
    enum_set = []
    hwpp.property_enum_entries.each do |enum|
      enum_set << enum.value
    end
    enum_set.should == value_array
  end
end
