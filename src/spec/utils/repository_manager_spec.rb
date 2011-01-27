require 'spec_helper'

describe RepositoryManager do
  before(:all) do
    @repositories_json = File.read(File.join(File.dirname(__FILE__),
                                             '../fixtures/repositories.json'))
    @packagegroups_json = File.read(File.join(File.dirname(__FILE__),
                                              '../fixtures/packagegroups.json'))
    @packages_json = File.read(File.join(File.dirname(__FILE__),
                                         '../fixtures/packages.json'))
    @packagegroupcategories_json = File.read(File.join(File.dirname(__FILE__),
                                                       '../fixtures/packagegroupcategories.json'))
  end

  before(:each) do
    hydra = Typhoeus::Hydra.hydra
    hydra.stub(:get, "http://pulptest/repositories/").and_return(
      Typhoeus::Response.new(:code => 200, :body => @repositories_json))
    hydra.stub(:get, "http://pulptest/repositories/fedora/packagegroups/").and_return(
      Typhoeus::Response.new(:code => 200, :body => @packagegroups_json))
    hydra.stub(:get, "http://pulptest/repositories/fedora/packages/").and_return(
      Typhoeus::Response.new(:code => 200, :body => @packages_json))
    hydra.stub(:get, "http://pulptest/repositories/fedora/packagegroupcategories/").and_return(
      Typhoeus::Response.new(:code => 200, :body => @packagegroupcategories_json))

    @rmanager = RepositoryManager.new(:config => [{
      'baseurl' => 'http://pulptest',
      'yumurl' => 'http://pulptest',
      'type'    => 'pulp',
    }])
  end

  it 'should return a list of repositories' do
    @rmanager.repositories.should have(1).items
    @rmanager.repositories.first.id.should eql('fedora')
  end

  it 'should return a list of packagegroups' do
    rep = @rmanager.repositories.first
    rep.groups.first[:id].should == 'aeolus'
  end

  it 'should return a list of categories' do
    @rmanager.categories.should have(1).items
    @rmanager.categories.first[:id].should eql('base-system')
  end

  it "should return a list of packages" do
    @rmanager.packages.should have(2).items
    @rmanager.packages.first[:name].should eql('libdeltacloud')
  end
end
