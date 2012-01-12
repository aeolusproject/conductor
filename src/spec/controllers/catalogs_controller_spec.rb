require "spec_helper"

describe CatalogsController do
  before do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    mock_warden(@admin)
  end

  describe "#destroy" do

    context "given empty catalog" do

      before(:all) do
        @catalog = Factory :catalog
      end

      it "delete an empty catalog a redirect to catalogs#index" do
        expect {delete :destroy, :id => @catalog.id}.to change(Catalog, :count).by(-1)
        response.should redirect_to catalogs_path
      end
    end

    context "given catalog with one deployable, that is included in other catalog" do
      before(:all) do
        @catalog = Factory :catalog_with_deployable
        @catalog2 = Factory :catalog
        Factory :catalog_entry, :catalog_id => @catalog2.id, :deployable_id => @catalog.deployables.first.id
      end

      it "successful delete catalog" do
        expect {delete :destroy, :id => @catalog.id}.to change(Catalog, :count).by(-1)
        response.should redirect_to catalogs_path
      end

      it "cannot remove catalog2 because it is the last deployable's reference " do
        delete :destroy, :id => @catalog.id
        expect {delete :destroy, :id => @catalog2.id}.not_to change(Catalog, :count).by(-1)
        response.should redirect_to catalog_path(@catalog2)
      end

    context "given catalog with one deployable, that is exclusive in this catalog" do
      before(:all) do
        @catalog = Factory :catalog_with_deployable
      end

      it "cannot be deleted when its deployables has no reference to other catalogs" do
        expect {delete :destroy, :id => @catalog.id}.not_to change(Catalog, :count).by(-1)
        response.should redirect_to catalog_path(@catalog)
      end
    end
    end

  end
end