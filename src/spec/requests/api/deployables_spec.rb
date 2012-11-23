require 'spec_helper'
require 'set'

describe "Deployabless" do
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
    end

    shared_examples_for "should return list of deployables" do
      let(:xml) { Nokogiri::XML(response.body) }
      let(:deployables) { Deployable.all } # assuming there are no other

      it { xml.xpath('/deployables').size.should == 1 }
      it { xml.xpath('/deployables/deployable').size.should == deployables.length }
      it "with correct IDs" do
        _ids = Deployable.all.map(&:id).map(&:to_s).to_set
        xml.xpath('/deployables/deployable/@id')
                 .map(&:value).to_set.should == _ids
      end
      it "with correct hrefs" do
        _hrefs = Deployable.all.map {|_d| deployable_url(_d)}.to_set
        xml.xpath('/deployables/deployable/@href')
                 .map(&:value).to_set.should == _hrefs
      end
    end

    shared_examples_for "response should be success & return xml" do
      it { response.should be_success }
      it { response.should have_content_type("application/xml") }
      it { response.body.should be_xml }
    end

    context "#index/list" do
      context "no deployables" do
        before do
          get 'deployables', nil, headers
        end

        it_behaves_like "response should be success & return xml"

        it "should return empty list" do
          xml = Nokogiri::XML(response.body)
          xml.xpath('/deployables').size.should == 1
          xml.xpath('/deployables/deployable').size.should == 0
        end

      end

      context "a catalog with some deployables" do
        before do
          _cid = FactoryGirl.create(:catalog_with_deployable).id
          get "catalogs/#{_cid}/deployables", nil, headers
        end

        it_behaves_like "response should be success & return xml"
        
        it_behaves_like "should return list of deployables"
      end

      context "deployables associated with some pool" do
        before do
          _pool = FactoryGirl.create(:pool_with_catalog_with_deployable)
          @depls = _pool.catalogs.map { |_c| _c.deployables }.reduce(&:+)
          get "pools/#{_pool.id}/deployables", nil, headers
        end

        it_behaves_like "response should be success & return xml"

        it_behaves_like "should return list of deployables"
      end
    end
  end
end
