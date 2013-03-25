require 'spec_helper'

describe "Catalogs" do
  let(:headers) { {
    'HTTP_ACCEPT' => 'application/xml',
    'CONTENT_TYPE' => 'application/xml'
  } }
  before(:each) do
    user = FactoryGirl.create(:admin_permission).user
    login_as(user)
  end

  describe "POST /api/catalogs" do
    before(:each) do
      post "/api/catalogs", xml, headers
    end

    context "with valid xml for nonexistent pool" do
      pool_id = 12 # ensure nonexistent pool_id
      while Pool.where(:id => pool_id+=1).first; end

      let(:xml) do
        '<catalog><name>haha</name><pool id="%s"/></catalog>' % pool_id
      end

      it_behaves_like 'http', 'Unprocessable Entity'
      it_behaves_like 'return xml'
    end
  end
end
