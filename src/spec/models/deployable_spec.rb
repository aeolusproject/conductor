require 'spec_helper'

describe Deployable do

  it "should have automatically generated uuid after validation" do
    d = Factory.build(:deployable)
    d.uuid = nil
    d.save
    d.uuid.should_not be_nil
  end

  it "should not be valid if deployable name is too long" do
    d = Factory.build(:deployable)
    d.name = ('a' * 256)
    d.valid?.should be_false
    d.errors[:name].should_not be_nil
    d.errors[:name].should =~ /^is too long.*/
  end

  it "should have associated assembly" do
    d = Factory.build(:deployable)
    d.assemblies.size.should eql(1)
  end

  it "should not be destroyable when it has running instances" do
    deployable = Factory.create(:deployable)
    deployment = Factory.create(:deployment, :deployable_id => deployable.id)
    assembly = Factory.create(:assembly)

    instance = Factory.create(:instance, :deployment_id => deployment.id, :assembly_id => assembly.id, :template_id => nil)
    Deployable.find(deployable).should_not be_destroyable

    instance.state = Instance::STATE_STOPPED
    instance.save!
    Deployable.find(deployable).should be_destroyable
  end

  it "should not be destroyable when it has stopped stateful instances" do
    deployable = Factory.build(:deployable)
    deployment = Factory.build(:deployment, :deployable_id => deployable.id)
    deployable.deployments << deployment
    assembly = Factory.build(:assembly)

    instance = Factory.build(:instance, :deployment_id => deployment.id, :assembly_id => assembly.id, :template_id => nil)
    instance.stub!(:restartable?).and_return(true)
    deployment.instances << instance
    deployable.should_not be_destroyable

    instance.state = Instance::STATE_STOPPED
    deployable.should_not be_destroyable

    instance.stub!(:restartable?).and_return(false)
    deployable.should be_destroyable
  end

end
