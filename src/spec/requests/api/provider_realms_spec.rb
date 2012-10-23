require 'spec_helper'

describe "ProviderRealms" do
  let(:headers) { {
      'HTTP_ACCEPT' => 'application/xml',
      'CONTENT_TYPE' => 'application/xml'
    } }

  context "API" do
    before(:each) do
      user = FactoryGirl.create(:admin_permission).user
      login_as(user)
      @provider = FactoryGirl.create(:mock_provider)
      @provider_account = FactoryGirl.create(:mock_provider_account)
      @frontend_realm_mapped_as_provider_realm = FactoryGirl.create(:frontend_realm)
      @provider.provider_realms.each do |prealm|
        @provider_account.provider_realms << prealm
        prealm.frontend_realms << @frontend_realm_mapped_as_provider_realm
      end
    end

    describe "#index" do

      it "get index" do
        get "/api/provider_realms", nil, headers

        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        xml.xpath("/provider_realms/provider_realm").size.should > 0
        @provider.provider_realms.each do |provider_realm|
          xml.xpath("/provider_realms/provider_realm[@id='#{provider_realm.id}']/@href").
            text.should == api_provider_realm_url(provider_realm.id)
        end
      end
    end

    describe "#show" do

      it "show provider realm" do
        provider_realm = @provider.provider_realms.first
        get "/api/provider_realms/#{provider_realm.id}", nil, headers
        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        xml.xpath("/provider_realm/@id").text.should == provider_realm.id.to_s
        xml.xpath("/provider_realm/@href").text.should == api_provider_realm_url(provider_realm)
        xml.xpath("/provider_realm/name").text.should == provider_realm.name
        xml.xpath("/provider_realm/external_key").text.should == provider_realm.external_key
        xml.xpath("/provider_realm/provider[@id='#{@provider.id}']/@href").
          text.should == api_provider_url(@provider)
        xml.xpath("/provider_realm/provider_accounts/provider_account[@id='#{@provider_account.id}']/@href").
          text.should == api_provider_account_url(@provider_account)
      end

      it "show nonexistent provider realm" do
        provider_realm = @provider.provider_realms.first
        get "/api/provider_realms/-1", nil, headers
        response.status.should == 404
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end

    end
  end
end
