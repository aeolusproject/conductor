require 'spec_helper'

describe "FrontendRealms" do
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
      @frontend_realm = FactoryGirl.create(:frontend_realm)
      # add provider realm
      @provider.provider_realms.each do |prealm|
        realm_backend_target = FactoryGirl.create(:realm_backend_target, :frontend_realm => @frontend_realm, :provider_realm_or_provider => prealm)
        @frontend_realm.realm_backend_targets << realm_backend_target
        #@frontend_realm.backend_realms << prealm
      end
      # add provider
      realm_backend_target = FactoryGirl.create(:realm_backend_target, :frontend_realm => @frontend_realm, :provider_realm_or_provider => @provider)
      @frontend_realm.realm_backend_targets << realm_backend_target
    end

    def check_frontend_realm_xml(xml_frontend_realm, frontend_realm)
      xml_frontend_realm.xpath("@id").text.should == frontend_realm.id.to_s
      xml_frontend_realm.xpath("@href").text.should == api_frontend_realm_url(frontend_realm)
      xml_frontend_realm.xpath("name").text.should == frontend_realm.name
      xml_frontend_realm.xpath("description").text.should == frontend_realm.description.to_s

      frontend_realm.backend_realms.each do |prealm|
        xml_frontend_realm.xpath("provider_realms/provider_realm[@id='#{prealm.id}']/@href").
          text.should == api_provider_realm_url(prealm)
      end

      frontend_realm.backend_providers.each do |provider|
        xml_frontend_realm.xpath("providers/provider[@id='#{provider.id}']/@href").
          text.should == api_provider_url(provider)
      end
    end

    describe "#index" do

      it "get index" do
        get "/api/frontend_realms", nil, headers

        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        xml.xpath("/frontend_realms/frontend_realm").size.should > 0
        xml.xpath("/frontend_realms/frontend_realm").size.should eq FrontendRealm.all.size
        FrontendRealm.all.each do |frontend_realm|
          xml.xpath("/frontend_realms/frontend_realm[@id='#{frontend_realm.id}']/@href").
            text.should == api_frontend_realm_url(frontend_realm.id)
          frontend_realm_xml = xml.xpath("/frontend_realms/frontend_realm[@id='#{frontend_realm.id}']")
          check_frontend_realm_xml(frontend_realm_xml, frontend_realm)
        end
      end
    end

    describe "#show" do

      it "show frontend realm" do
        @frontend_realm.backend_realms.size.should > 0
        @frontend_realm.backend_providers.size.should > 0

        get "/api/frontend_realms/#{@frontend_realm.id}", nil, headers
        response.should be_success
        response.should have_content_type("application/xml")
        response.body.should be_xml
        xml = Nokogiri::XML(response.body)

        check_frontend_realm_xml(xml.xpath("/frontend_realm"), @frontend_realm)
      end

      it "show nonexistent frontend realm" do
        get "/api/frontend_realms/-1", nil, headers
        response.status.should == 404
        response.should have_content_type("application/xml")
        response.body.should be_xml
      end

    end
  end
end
