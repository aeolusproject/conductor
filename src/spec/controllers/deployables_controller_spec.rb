#
#   Copyright 2011 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'spec_helper'

describe DeployablesController do

  fixtures :all
  before do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    mock_warden(@admin)
    @catalog = FactoryGirl.create(:catalog)
  end

  describe "#new" do
    context "with params[:create_from_image]" do
      before do
        @deployable = stub_model(Deployable, :name => "test_new", :id => 1)
        @image = FactoryGirl.create(:base_image_with_template)
      end

      it "returns flash[:error] when no hardware profile exists" do
        get :new, :create_from_image => @image.id
        flash[:error].should_not be_empty
      end

      it "returns flash[:error] when no catalog and hardware profile exists" do
        Catalog.stub(:list_for_user).and_return(Catalog.includes(:pool).where("1=0"))
        get :new, :create_from_image => @image.id
        flash[:error].should_not be_empty
      end

      it "returns flash[:error] when no catalog exists" do
        Catalog.stub(:list_for_user).and_return(Catalog.includes(:pool).where("1=0"))
        HardwareProfile.stub(:list_for_user).and_return([mock(HardwareProfile)])
        get :new, :create_from_image => @image.id
        flash[:error].should eql(["No Catalog exists. Please create one."])
      end
    end
  end

  describe "#create" do
    before(:each) do
      @image = FactoryGirl.create(:base_image_with_template)
      @catalog2 = FactoryGirl.create(:catalog)
    end

    it "shows 'new' deployable from image via UI" do
      c1 = Deployable.all.size
      get :new, :create_from_image => @image.id
      response.should be_success
      response.should render_template("new")
      c2 = Deployable.all.size
      (c2 - c1).should eql(0)
    end

    it "creates new deployable from image via POST" do
      hw_profile = FactoryGirl.create(:front_hwp1)
      c1 = Deployable.all.size
      post(:create, :create_from_image => @image.id, :deployable => {:name => @image.name}, :hardware_profile => hw_profile.id, :catalog_id => @catalog.id)
      response.should be_redirect
      c2 = Deployable.all.size
      (c2 - c1).should eql(1)
    end

    it "should redirect if :cancel is in params and there should be no new deployable" do
      hw_profile = FactoryGirl.create(:front_hwp1)
      c1 = Deployable.all.size
      post(:create, :cancel => true, :create_from_image => @image.id, :deployable => {:name => @image.name}, :hardware_profile => hw_profile.id, :catalog_id => @catalog.id)
      response.should be_redirect  # getting 500 instead
      c2 = Deployable.all.size
      (c2 - c1).should eql(0)
    end

    it "creates new deployable from image when more catalogs are spec'd + shows notice" do
      hw_profile = FactoryGirl.create(:front_hwp1)
      c1 = Deployable.all.size
      post(:create, :create_from_image => @image.id,
           :deployable => {:name => @image.name}, :hardware_profile => hw_profile.id,
           :catalog_id => [@catalog.id, @catalog2.id])
      response.should be_redirect
      flash[:notice].should eql("Deployable added to Catalog #{@catalog.name}, #{@catalog2.name}.")
      c2 = Deployable.all.size
      (c2 - c1).should eql(1)
    end

    it "returns flash[:warning] when there is no selected_catalog" do
      Catalog.stub(:find).and_return(Catalog.where('1=0'))
      hw_profile = FactoryGirl.create(:front_hwp1)
      c1 = Deployable.all.size
      post(:create, :deployable => {:name => @image.name},
           :hardware_profile => hw_profile.id, :catalog_id => @catalog.id)
      response.should be_success
      flash[:warning].should eql("Deployable was not created: No Catalogs selected")
      c2 = Deployable.all.size
      (c2 - c1).should eql(0)
    end
  end

  describe "#destroy" do
    before do
      @deployable = stub_model(Deployable, :name => "test_delete", :id => 1)
      Deployable.stub(:find).and_return(@deployable)
    end


    context "deletion successfully" do
      before do
        Deployable.any_instance.stub(:destroy).and_return(true)
        Deployable.any_instance.stub(:has_privilege).and_return(true)
      end

      it "deletes a deployable and redirect to deployables#index" do
        delete :destroy, :id => @deployable.id
        response.should redirect_to deployables_path
      end

      it "deletes a deployable and appears flash notice" do
        delete :destroy, :id => @deployable.id
        flash[:notice].should_not be_empty
      end
    end

    context "deletion fails" do
      before do
        Deployable.any_instance.stub(:destroy).and_return(false)
        Deployable.any_instance.stub(:has_privilege).and_return(true)
      end

      it "not delete a deployable and redirect to deployables#show" do
        delete :destroy, :id => @deployable.id
        response.should redirect_to deployables_path
      end

      it "not delete a deployable and shows flash error" do
        delete :destroy, :id => @deployable.id
        flash[:error].should_not be_empty
      end
    end
  end

  describe "#multi_destroy" do
    it "redirects to deployables#index" do
        delete :multi_destroy
        response.should redirect_to deployables_path
      end

    context "with params[:deployables_selected]" do
      before do
        @deployable1 = Factory :deployable, :name => "test_delete", :catalogs => [@catalog]
        @deployable2 = Factory :deployable, :name => "test_delete2", :catalogs => [@catalog]
      end

      it "deletes both deployables and shows flash notice" do
        delete :multi_destroy, :deployables_selected => [@deployable1.id, @deployable2.id]
        flash[:notice].should_not be_empty
      end

      it "not delete deployable1 but not deployable2 and shows flash notice and error" do
        CatalogEntry.any_instance.stub(:destroy).and_return(false)
        delete :multi_destroy, :deployables_selected => [@deployable1.id, @deployable2.id], :catalog_id => @catalog.id
        flash[:error].should_not be_empty
      end

      it "not delete deployable with multiple catalogs" do
        @catalog2 = FactoryGirl.create(:catalog)
        @catalog2.deployables << @deployable1
        delete :multi_destroy, :deployables_selected => [@deployable1.id], :catalog_id => @catalog.id
        @deployable1.should_not be_nil
      end

      context "without params[:deployables_selected]" do
        it "not delete a deployable and shows flash error" do
          delete :multi_destroy, :catalog_id => @catalog.id
          flash[:error].should_not be_empty
        end
      end
    end
  end

end
