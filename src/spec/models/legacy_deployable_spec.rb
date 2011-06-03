require 'spec_helper'

describe LegacyDeployable do

  it "should have automatically generated uuid after validation" do
    d = Factory.build(:legacy_deployable)
    d.uuid = nil
    d.save
    d.uuid.should_not be_nil
  end

  it "should not be valid if deployable name is too long" do
    d = Factory.build(:legacy_deployable)
    d.name = ('a' * 256)
    d.valid?.should be_false
    d.errors[:name].should_not be_nil
    d.errors[:name].should =~ /^is too long.*/
  end

  it "should have associated assembly" do
    d = Factory.build(:legacy_deployable)
    d.legacy_assemblies.size.should eql(1)
  end

  it "should not be destroyable when it has running instances" do
    deployable = Factory.create(:legacy_deployable)
    deployment = Factory.create(:deployment, :legacy_deployable_id => deployable.id)
    assembly = Factory.create(:legacy_assembly)

    instance = Factory.create(:instance, :deployment_id => deployment.id, :legacy_assembly_id => assembly.id, :legacy_template_id => nil)
    LegacyDeployable.find(deployable).should_not be_destroyable

    instance.state = Instance::STATE_STOPPED
    instance.save!
    LegacyDeployable.find(deployable).should be_destroyable
  end

  it "should not be destroyable when it has stopped stateful instances" do
    deployable = Factory.build(:legacy_deployable)
    deployment = Factory.build(:deployment, :legacy_deployable_id => deployable.id)
    deployable.deployments << deployment
    assembly = Factory.build(:legacy_assembly)

    instance = Factory.build(:instance, :deployment_id => deployment.id, :legacy_assembly_id => assembly.id, :legacy_template_id => nil)
    instance.stub!(:restartable?).and_return(true)
    deployment.instances << instance
    deployable.should_not be_destroyable

    instance.state = Instance::STATE_STOPPED
    deployable.should_not be_destroyable

    instance.stub!(:restartable?).and_return(false)
    deployable.should be_destroyable
  end

end
