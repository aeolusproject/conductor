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
require 'aeolus_image'

describe Api::ProviderImagesController do
  render_views
  context "create helper methods" do

    describe "#find_target_image_for_account" do

      before(:each) do
        @controller = Api::ProviderImagesController.new
        provider = FactoryGirl.create :mock_provider_for_vcr_data
        @account = provider.provider_accounts.first

        image = mock(Aeolus::Image::Warehouse::Image, :id => '3c58e0d6-d11a-4e68-8b12-233783e56d35')
        build = mock(Aeolus::Image::Warehouse::ImageBuild, :id => '93e43784-114d-431c-a775-61261baed80f',
                                                           :image => image)
        @mock_target_image = mock(Aeolus::Image::Warehouse::TargetImage, :id => '42691826-7e02-4256-9d5d-5720d6fd58e0',
                                                                         :target => 'mock',
                                                                         :build => build)
        @ec2_target_image = mock(Aeolus::Image::Warehouse::TargetImage, :id => 'c69e4be2-5596-4523-8eb8-c6ba97cbed4f',
                                                                        :target => 'ec2',
                                                                        :build => build)
      end

      it "should return the correct target image when a match is found" do
        @controller.find_target_image_for_account([@ec2_target_image, @mock_target_image], @account).should == @mock_target_image
      end

      it "should return the nil when no match is found" do
        @controller.find_target_image_for_account([@ec2_target_image, @ec2_target_image], @account).should == nil
      end
    end

    describe "#list_target_images" do

      before(:each) do
        @target_image = mock(Aeolus::Image::Warehouse::TargetImage, :id => '42691826-7e02-4256-9d5d-5720d6fd58e0',
                                                                    :target => 'mock',
                                                                    :build => @build)
        @build1 = mock(Aeolus::Image::Warehouse::ImageBuild, :target_images => [@target_image, @target_image])
        @build2 = mock(Aeolus::Image::Warehouse::ImageBuild, :target_images => [@target_image, @target_image])
        @image = mock(Aeolus::Image::Warehouse::Image, :image_builds => [@build1, @build2], :environment => 'default')
      end

      it "should raise bad request when no provider account is given" do
        begin
          doc = Nokogiri::XML CGI.unescapeHTML "<provider_image></provider_image>"
          @controller.list_target_images(doc)
        rescue => e
          e.instance_of?(Aeolus::Conductor::API::InsufficientParametersSupplied).should == true
        end
      end

      it "should return a single target image when a target image is provided" do
        doc = Nokogiri::XML "<provider_image>
                               <provider_account>MockAccount</provider_account>
                               <target_image_id>1234</image_id>
                             </provider_image>"
        Aeolus::Image::Warehouse::TargetImage.stub(:find).and_return(@target_image)
        @controller.list_target_images(doc).size.should == 1
      end

      it "should return a list of target images when a build is provided" do
        doc = Nokogiri::XML "<provider_image>
                               <provider_account>MockAccount</provider_account>
                               <build_id>1234</image_id>
                             </provider_image>"
        Aeolus::Image::Warehouse::ImageBuild.stub(:find).and_return(@build1)
        @controller.list_target_images(doc).size.should == 2
      end

      it "should return a list of target images when an image is provided" do
        doc = Nokogiri::XML "<provider_image>
                               <provider_account>MockAccount</provider_account>
                               <image_id>1234</image_id>
                             </provider_image>"
        Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
        @controller.list_target_images(doc).size.should == 4
      end
    end
  end

  shared_examples_for "Api::ProviderImagesController responding with XML" do
    before(:each) do
      send_and_accept_xml

      @timage = mock(Aeolus::Image::Warehouse::TargetImage,
                     :id => '300')
      @pimage = mock(Aeolus::Image::Warehouse::ProviderImage,
                     :id => '17',
                     :provider_name => 'provider_name',
                     :provider => "provider",
                     :object_type => 'provider_image',
                     :account => 'account',
                     :target_identifier => '80',
                     :target_image => @timage)
    end

    context "when authenticated as admin" do

      before(:each) do
        @admin_permission = FactoryGirl.create :admin_permission
        @admin = @admin_permission.user
        mock_warden(@admin)
      end

      describe "#index" do

        context "when there are 3 provider images" do

          before(:each) do
            @provider_image_collection = [@pimage, @pimage, @pimage]
            Aeolus::Image::Warehouse::ProviderImage.stub(:all).and_return(@provider_image_collection)
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have 3 provider images" do
            resp = Hash.from_xml(response.body)
            resp['provider_images']['provider_image'].size.should be_equal(@provider_image_collection.size)
          end
          it "should have provider images with corrent attributes" do
            resp = Hash.from_xml(response.body)
            @provider_image_collection.each_with_index do |pimage, index|
              resp['provider_images']['provider_image'][index]['id'].should == pimage.id
              resp['provider_images']['provider_image'][index]['object_type'].should == pimage.object_type
              resp['provider_images']['provider_image'][index]['target_identifier'].should == pimage.target_identifier
              resp['provider_images']['provider_image'][index]['target_image']['id'].should == pimage.target_image.id
            end
          end
        end

        context "when there is only 1 provider image" do

          before(:each) do
            Aeolus::Image::Warehouse::ProviderImage.stub(:all).and_return([@pimage])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have a provider image with corrent attributes" do
            resp = Hash.from_xml(response.body)
            resp['provider_images']['provider_image']['id'].should == @pimage.id
            resp['provider_images']['provider_image']['object_type'].should == @pimage.object_type
            resp['provider_images']['provider_image']['target_identifier'].should == @pimage.target_identifier
            resp['provider_images']['provider_image']['target_image']['id'].should == @pimage.target_image.id
          end
        end

        context "when there is no provider image" do

          before(:each) do
            Aeolus::Image::Warehouse::ProviderImage.stub(:all).and_return([])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have no provider image" do
            resp = Hash.from_xml(response.body)
            resp['provider_images']['provider_image'].should be_nil
          end
        end

      end

      describe "#show" do

        context "when there is wanted provider image" do

          before do
            Aeolus::Image::Warehouse::ProviderImage.stub(:find).and_return(@pimage)
            get :show, :id => '5'
          end

          it { response.should be_success}
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have a provider image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['provider_image']['id'].should == @pimage.id
            resp['provider_image']['provider'].should == @pimage.provider_name
            resp['provider_image']['object_type'].should == @pimage.object_type
            resp['provider_image']['target_identifier'].should == @pimage.target_identifier
            resp['provider_image']['target_image']['id'].should == @pimage.target_image.id
          end
        end

        context "when there is NOT wanted provider image in warehouse" do
          before(:each) do

            Aeolus::Image::Warehouse::ProviderImage.stub(:find).and_return(nil)
          end

          context "and it has status in factory" do
            before(:each) do
              @pimage_status = 'COMPLETE'
              Aeolus::Image::Factory::ProviderImage.stub(:status).and_return(@pimage_status)
              @pimage_id = '100'
              get :show, :id => @pimage_id
            end

            it { response.should be_success}
            it { response.headers['Content-Type'].should include("application/xml") }
            it "should have a provider image with correct attributes" do
              resp = Hash.from_xml(response.body)
              resp['provider_image']['id'].should == @pimage_id;
              resp['provider_image']['status'].should == @pimage_status;
            end
          end

          context "and it has NOT status in factory" do
            before(:each) do
              Aeolus::Image::Factory::ProviderImage.stub(:status).and_return(nil)
              get :show, :id => '100'
            end

            it { response.should be_not_found}
            it { response.headers['Content-Type'].should include("application/xml") }
            it "should have error" do
              resp = Hash.from_xml(response.body)
              resp['error']['code'].should == "ProviderImageStatusNotFound"
              resp['error']['message'].should == "Could not find status for ProviderImage 100"
            end
          end
       end

        describe "#create" do
          context "with incomplete parameters" do
            before(:each) do
              Aeolus::Image::Factory::ProviderImage.stub(:status).and_return(nil)
              get :create, :id => '100'
            end

            it { response.headers['Content-Type'].should include("application/xml") }
            it { response.status.should == 400}
            it "should have error" do
              resp = Hash.from_xml(response.body)
              resp['error']['code'].should == "InsufficientParametersSupplied"
              resp['error']['message'].should == "No Provider Account given"
            end
          end
        end

        describe "#destroy" do
          context "and deleting an object that doesn't exist" do
            before(:each) do
              Aeolus::Image::Factory::ProviderImage.stub(:status).and_return(nil)
              Aeolus::Image::Warehouse::ProviderImage.stub(:find).and_return(nil)
              get :destroy, :id => '99'
            end

            it { response.headers['Content-Type'].should include("application/xml") }
            it { response.status.should == 404}
            it "should have error" do
              resp = Hash.from_xml(response.body)
              resp['error']['code'].should == "ProviderImageNotFound"
              resp['error']['message'].should == "Could not find ProviderImage 99"
            end
          end
        end
      end

      describe "#destroy" do
        before(:each) do
          send_and_accept_xml
        end

        context "when image exists" do
          before(:each) do
            Aeolus::Image::Warehouse::ProviderImage.stub(:find).and_return(@pimage)
          end

          context "and delete succeeds" do
            before(:each) do
              @pimage.stub(:delete!).and_return(true)

              delete :destroy, :id => @pimage.id
            end

            it { response.should be_success}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

          context "and delete fails" do
            before(:each) do
              @pimage.stub(:delete!).and_throw(Exception)

              delete :destroy, :id => @pimage.id
            end

            it { response.status.should == 500}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

        end

        context "when image is not found" do
          before(:each) do
            Aeolus::Image::Warehouse::ProviderImage.stub(:find).and_return(nil)
            delete :destroy, :id => @pimage.id
          end

          it { response.status.should == 404}
          it { response.headers['Content-Type'].should include("application/xml") }
        end


      end

      describe "#create" do
        context "when posting empty request" do
          before(:each) do
            post :create
          end

          it {response.response_code.should == 400}
        end

        context "when posting invalid xml" do
          before(:each) do
            request.env['RAW_POST_DATA'] = "<xml></xml>"
            post :create
          end

          it {response.response_code.should == 400}
        end

        context "when trying to build image" do
          before(:each) do
            @provider_account = FactoryGirl.create :mock_provider_account
            @provider_account.pool_families = [ PoolFamily.find_by_name('default') ]
            xml = Nokogiri::XML::Builder.new do |x|
              x.provider_image {
                x.image_id "17"
                x.build_id "8"
                x.target_image_id "9"
                x.provider_account @provider_account.label
                x.provider_name "mock"
              }
            end
            Aeolus::Image::Factory::ProviderImage.stub(:status).and_return("nil")
            Aeolus::Image::Factory::ProviderImage.stub(:new).and_return(@pimage)
            @target_image = mock(Aeolus::Image::Warehouse::TargetImage, :id => '42691826-7e02-4256-9d5d-5720d6fd58e0',
                                                                        :target => 'mock')
            @build1 = mock(Aeolus::Image::Warehouse::ImageBuild, :id=>'3', :target_images => [@target_image, @target_image])
            @build2 = mock(Aeolus::Image::Warehouse::ImageBuild, :id=>'2', :target_images => [@target_image, @target_image])
            @image = mock(Aeolus::Image::Warehouse::Image, :id=>'1', :image_builds => [@build1, @build2], :environment => 'default')

            @build1.stub(:image).and_return(@image)
            @build2.stub(:image).and_return(@image)
            @target_image.stub(:build).and_return(@build1)

            Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
            controller.stub(:send_push_request).and_return(@pimage)

            request.env['RAW_POST_DATA'] = xml.to_xml
            post :create
          end

          it { response.response_code == 200 }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have an image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['provider_images']['provider_image']['id'].should == "17"
            resp['provider_images']['provider_image']['status'].should == "nil"
         end
        end

      end


    end

    context "when not authenticated" do

      before(:each) do
        mock_warden(nil)
      end

      describe "#index" do

        before(:each) do
          get :index
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

      describe "#show" do

        before(:each) do
          get :show, :id => '5'
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

      describe "#destroy" do

        before(:each) do
          delete :destroy, :id => '5'
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

      describe "#create" do

        before(:each) do
          post :create, :id => '5'
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

    end
  end

  context "XML format responses for Accept: application/xml" do
    before(:each) do
      send_and_accept_xml
    end

    it_behaves_like "Api::ProviderImagesController responding with XML"
  end

  context "XML format responses for Accept: */*" do
    before(:each) do
      accept_all
    end

    it_behaves_like "Api::ProviderImagesController responding with XML"
  end

end
