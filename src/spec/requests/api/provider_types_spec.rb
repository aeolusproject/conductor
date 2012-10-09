require 'spec_helper'

describe "ProviderTypes" do

  shared_examples_for "having XML with provider types" do
    subject { Nokogiri::XML(response.body) }
    context "list of provider types" do
      let(:xml_provider_types) { subject.xpath('//provider_types/provider_type') }
      context "number of provider types" do
        it { ProviderType.all; xml_provider_types.size.should be_eql(number_of_provider_types) }
      end
      it "should have correct provider types" do
        provider_types.each do |provider_type|
          xml_provider_type = xml_provider_types.xpath("//provider_type[@id=\"#{provider_type.id}\"]")
          xml_provider_type.xpath('@href').text.should be_eql(api_provider_type_url(provider_type))
          # it should have details of provider_types
          %w{name deltacloud_driver}.each do |element|
            xml_provider_type.xpath(element).text.should be_eql(provider_type.attributes[element])
          end
          # it should not have details of provider_types
          %w{ssh_user home_dir}.each do |element|
            xml_provider_type.xpath(element).should be_empty
          end
        end
      end
    end
  end

  let(:headers) { {
    'HTTP_ACCEPT' => 'application/xml',
    'CONTENT_TYPE' => 'application/xml'
  } }
  before(:each) do
    user = FactoryGirl.create(:admin_permission).user
    login_as(user)
  end

  describe "GET /api/provider_types" do
    let(:number_of_provider_types) { 3 }
    let!(:provider_types) { ProviderType.destroy_all; number_of_provider_types.times{ FactoryGirl.create(:provider_type) }; ProviderType.all }

    before(:each) do
      resp = get '/api/provider_types', nil, headers
    end

    it_behaves_like "http OK"
    it_behaves_like "responding with XML"

    context "XML body" do
      it_behaves_like "having XML with provider types"
    end
  end
end
