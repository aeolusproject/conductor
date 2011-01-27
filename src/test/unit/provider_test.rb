require File.dirname(__FILE__) + '/../test_helper'

class ProviderTest < ActiveSupport::TestCase
  fixtures :providers

  def setup
    @provider = Provider.new(:name => "my_ec2",
                             :provider_type => "EC2")
  end
  # The following three tests assume you have the deltacloud-framework
  # running and configured on localhost:3000

  test "is valid with good url" do
    @provider.url = "http://localhost:3000/api"
    flunk "That URL should have worked. Is framework running?" if @provider.invalid?
  end

  test "requires url" do
    flunk "Providers require a url" if @provider.valid?
  end

  test "fails with invalid provider url" do
    @provider.url = "http://conductor.awesome/api"
    flunk "Invalid url passed validation" unless @provider.invalid?
  end

  test "should return nil if no connection" do
    assert_equal(nil, @provider.connect)
  end

  test "should return DeltaCloud if successful connection" do
    @provider.url = "http://localhost:3000/api"
    assert_instance_of(DeltaCloud, @provider.connect)
  end
end
