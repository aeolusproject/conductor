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

    shared_examples_for "having XML with provider type" do
      subject { Nokogiri::XML(response.body) }
      it "should have correct provider type" do
        xml_provider_type = subject.xpath("//provider_type")
        xml_provider_type.xpath('@id').text.should be_eql(provider_type.id.to_s)
        xml_provider_type.xpath('@href').text.should be_eql(api_provider_type_url(provider_type))
        # it should have details of provider_types
        %w{name deltacloud_driver ssh_user home_dir}.each do |element|
          xml_provider_type.xpath(element).text.should be_eql(provider_type.attributes[element].to_s)
        end
        # it should not have details of provider_types
        %w{}.each do |element|
          xml_provider_type.xpath(element).should be_empty
        end
      end
      it "should have correct set of credential definitions" do
        xml_credential_definitions = subject.xpath("//provider_type/credential_definitions")
        # puts provider_type.inspect
        # puts provider_type.credential_definitions.inspect
        provider_type.credential_definitions.each do |credential_definition|
          xml_credential_definition = xml_credential_definitions.xpath("//credential_definition[@id=\"#{credential_definition.id}\"]")
          # it should have details for credential definition
          %w{name label input_type}.each do |element|
            xml_credential_definition.xpath(element).text.should be_eql(credential_definition.attributes[element].to_s)
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

  describe "GET /api/provider_types/:id" do
    let!(:provider_type) { FactoryGirl.create(:provider_type_with_credential_definitions) }

    context "provider type exists" do
      before(:each) do
        get "/api/provider_types/#{provider_type.id}", nil, headers
      end

      it_behaves_like "http OK"
      it_behaves_like "responding with XML"

      context "XML body" do
        it_behaves_like "having XML with provider type"
      end
    end

    context "provider type does not exist" do

       before(:each) do
         provider_type.destroy
         get "/api/provider_types/#{provider_type.id}", nil, headers
       end

       it_behaves_like "http Not Found"
       it_behaves_like "responding with XML"
    end
  end

  describe "DELETE /api/provider_types/:id" do
    let!(:provider_type) { FactoryGirl.create(:provider_type_with_credential_definitions) }

    context "provider type exists" do
      before(:each) do
        @provider_type_count = ProviderType.count
        delete "/api/provider_types/#{provider_type.id}", nil, headers
      end

      it_behaves_like "http No Content"

      it "should be deleted" do
        expect { ProviderType.find(provider_type.id) }.to raise_error( ActiveRecord::RecordNotFound )
      end

      it "should not delete other provider types" do
        ( @provider_type_count - ProviderType.count ).should eql( 1 )
      end
    end

    context "provider type does not exist" do
      before(:each) do
        ProviderType.destroy(provider_type.id)
        @provider_type_count = ProviderType.count
        delete "/api/provider_types/#{provider_type.id}", nil, headers
      end

      it_behaves_like "http Not Found"
      it_behaves_like "responding with XML"

      it "should not delete any provider type" do
        ProviderType.count.should eql( @provider_type_count )
      end
    end
  end
end
