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
end
