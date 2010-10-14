require 'spec_helper'

describe RepositoryManager do
  before(:all) do
    @repositories_json = File.read(File.join(File.dirname(__FILE__),
                                             '../fixtures/repositories.json'))
    @packagegroups_json = File.read(File.join(File.dirname(__FILE__),
                                              '../fixtures/packagegroups.json'))
    @packages_json = File.read(File.join(File.dirname(__FILE__),
                                         '../fixtures/packages.json'))
  end

  before(:each) do
    hydra = Typhoeus::Hydra.hydra
    hydra.stub(:get, "http://pulptest/repositories/").and_return(
      Typhoeus::Response.new(:code => 200, :body => @repositories_json))
    hydra.stub(:get, "http://pulptest/repositories/jboss/packagegroups/").and_return(
      Typhoeus::Response.new(:code => 200, :body => @packagegroups_json))
    hydra.stub(:get, "http://pulptest/repositories/jboss/packages/").and_return(
      Typhoeus::Response.new(:code => 200, :body => @packages_json))
    hydra.stub(:get, "http://nonexisting.repo/").and_return(
      Typhoeus::Response.new(:code => 404))

    @rmanager = RepositoryManager.new(:config => [{
      'baseurl' => 'http://pulptest',
      'yumurl' => 'http://pulptest',
      'type'    => 'pulp',
    }])
  end

  it "should return a list of repositories" do
    @rmanager.repositories.should have(1).items
    @rmanager.repositories.first.id.should eql('jboss')
  end

  it "should return a list of packagegroups" do
    rep = @rmanager.repositories.first
    rep.groups.keys.sort.should == ["JBoss Core Packages", "JBoss Drools",
      "JBoss Social Networking Web Application"]
  end

  it "should raise exception when downloading of repomd fails" do
    @rmanager = RepositoryManager.new(:config => [{
      'baseurl' => 'http://nonexisting.repo/',
      'type'    => 'xml',
    }])
    lambda { @rmanager.all_groups}.should raise_error
  end
end
