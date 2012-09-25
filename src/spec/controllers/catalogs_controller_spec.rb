require "spec_helper"

describe CatalogsController do
  before do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    mock_warden(@admin)
  end

  describe "#destroy" do

    context "given empty catalog" do

      before(:each) do
        @catalog = Factory :catalog
      end

      it "delete an empty catalog a redirect to catalogs#index" do
        expect {delete :destroy, :id => @catalog.id}.to change(Catalog, :count).by(-1)
        response.should redirect_to catalogs_path
      end
    end

    context "given catalog with one deployable, that is included in other catalog" do
      before(:each) do
        @catalog = Factory :catalog_with_deployable
        @catalog2 = Factory :catalog
        Factory :catalog_entry, :catalog_id => @catalog2.id, :deployable_id => @catalog.deployables.first.id
      end

      it "successful delete catalog" do
        expect {delete :destroy, :id => @catalog.id}.to change(Catalog, :count).by(-1)
        response.should redirect_to catalogs_path
      end

      it "cannot remove deployable related to catalog because it is also related to catalog2" do
        expect {delete :destroy, :id => @catalog.id}.not_to change(Deployable, :count)
        response.should redirect_to catalogs_path
      end

    context "given catalog with one deployable, that is exclusive in this catalog" do
      before(:each) do
        @catalog = Factory :catalog_with_deployable
      end

      it "should delete its deployables if its deployables have no reference to other catalogs" do
        expect {delete :destroy, :id => @catalog.id}.to change(Deployable, :count).by(-1)
        response.should redirect_to catalogs_path
      end
    end
    end

  end

  context "API" do
    render_views

    before do
      send_and_accept_xml
    end

    describe "#index" do
      before do
        get :index
      end

      it_behaves_like "http OK"
      it_behaves_like "responding with XML"

      it "should print list of catalogs" do
        xml = Nokogiri::XML(response.body)
        # contains only default catalog
        xml.xpath("//catalogs/catalog").size.should == 1
      end
    end

    describe "#show a catalog with a deployable" do
      before do
        @catalog = FactoryGirl.create :catalog_with_deployable, :name => 'test catalog'
        get :show, :id => @catalog.id
      end

      it_behaves_like "http OK"
      it_behaves_like "responding with XML"

      it "should print catalog details" do
        xml = Nokogiri::XML(response.body)
        xml.xpath("//catalog/name").text.should == @catalog.name
        xml.xpath("//catalog/@id").text.should == @catalog.id.to_s
        xml.xpath("//catalog/@href").text.should == api_catalog_url(@catalog.id)
        xml.xpath("//catalog/pool/@id").text.should == @catalog.pool_id.to_s
        xml.xpath("//catalog/pool/@href").text.should == api_pool_url(@catalog.pool_id)
      end

      it "should list catalog's deployables" do
        xml = Nokogiri::XML(response.body)
        xml.xpath("//catalog/deployables/deployable/@id").text.should == @catalog.deployables[0].id.to_s
      end
    end

    describe "#create a catalog" do
      before do
        @catalog = FactoryGirl.build(:catalog)

        post :create, {
          :catalog => {
            :name => @catalog.name,
            :pool => {
              :id => @catalog.pool_id
            }
          }
        }
      end

      it_behaves_like "http OK"
      it_behaves_like "responding with XML"

      it "should print catalog details" do
        xml = Nokogiri::XML(response.body)
        xml.xpath("//catalog/name").text.should == @catalog.name
        xml.xpath("//catalog/@href").text.should == api_catalog_url(xml.xpath("//catalog/@id").text.to_i)
        xml.xpath("//catalog/pool/@id").text.should == @catalog.pool_id.to_s
        xml.xpath("//catalog/pool/@href").text.should == api_pool_url(@catalog.pool_id)
      end

      it "should print empty list of deployables" do
        xml = Nokogiri::XML(response.body)
        xml.xpath("//catalog/deployables").size.should == 1
        xml.xpath("//catalog/deployables/deployable").size.should == 0
      end
    end
  end
end
