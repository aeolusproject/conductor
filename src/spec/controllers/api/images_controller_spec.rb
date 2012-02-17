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

describe Api::ImagesController do
  render_views

  shared_examples_for "Api::ImagesController responding with XML" do

    before(:each) do

      @os = mock(:OS, :name => 'fedora', :version => '15', :arch => 'x86_64')
      @build = mock(Aeolus::Image::Warehouse::ImageBuild,
                    :id => '7',
                    :target_images => [])
      @provider_image = mock(Aeolus::Image::Warehouse::ProviderImage,
                    :target_identifier => "ami-1234567",
                    :provider => "provider")
      @image = mock(Aeolus::Image::Warehouse::Image,
                    :id => '5',
                    :environment => 'default',
                    :os => @os,
                    :name => 'test',
                    :description => 'test image',
                    :image_builds => [@build],
                    :build => @build,
                    :provider_images => [@provider_image, @provider_image.clone],
                    :uuid => '94dc260c-5821-11e1-9477-70f395039857'
                    )
      @provider_type = mock(ProviderType,
                    :name => 'mock',
                    :deltacloud_driver => 'mock')
      @provider = mock(Provider,
                    :name => 'mock',
                    :enabled => true,
                    :provider_type => @provider_type)
      @provider_account = mock(ProviderAccount,
                    :label => 'mock',
                    :provider => @provider,
                    :credentials_hash => {'username' => 'foo', 'password' => 'bar'})
      @environment = mock(PoolFamily, :name => 'default')
      ProviderAccount.any_instance.stub(:pool_families).and_return([@environment])
      ProviderAccount.stub(:group_by_type).and_return(
                                 "mock" => {:type => @provider_type,
                                            :included => true,
                                            :accounts => [@provider_account, true]})
      PoolFamily.any_instance.stub(:provider_accounts).and_return([@provider_account])
      Aeolus::Image::Warehouse::ImageBuild.stub(:where).and_return([@build])
    end

    context "when authenticated as admin" do

      before(:each) do
        @admin_permission = FactoryGirl.create :admin_permission
        @admin = @admin_permission.user
        mock_warden(@admin)
      end

      describe "#index" do

        context "when there are 3 images" do

          before(:each) do
            @image_collection = [@image, @image, @image]
            Aeolus::Image::Warehouse::Image.stub(:all).and_return(@image_collection)
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have 3 images" do
            resp = Hash.from_xml(response.body)
            resp['images']['image'].size.should be_equal(@image_collection.size)
          end

          it "should have images with correct attributes" do
            resp = Hash.from_xml(response.body)
            @image_collection.each_with_index do |image, index|
              resp['images']['image'][index]['name'].should == image.name
              resp['images']['image'][index]['id'].should == image.id
              resp['images']['image'][index]['environment'].should == image.environment
              resp['images']['image'][index]['os'].should == image.os.name
              resp['images']['image'][index]['arch'].should == image.os.arch
              resp['images']['image'][index]['os_version'].should == image.os.version
              resp['images']['image'][index]['description'].should == image.description
              resp['images']['image'][index]['builds']['build']['id'].should == @build.id
            end
          end

        end

        context "when there is only 1 image" do

          before(:each) do
            Aeolus::Image::Warehouse::Image.stub(:all).and_return([@image])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have an image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['images']['image']['name'].should == @image.name
            resp['images']['image']['id'].should == @image.id
            resp['images']['image']['environment'].should == @image.environment
            resp['images']['image']['os'].should == @image.os.name
            resp['images']['image']['arch'].should == @image.os.arch
            resp['images']['image']['os_version'].should == @image.os.version
            resp['images']['image']['description'].should == @image.description
          end

        end

        context "when there is no image" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:all).and_return([])
            get :index
          end

          it { response.should be_success }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have no image" do
            resp = Hash.from_xml(response.body)
            resp['images']['image'].should be_nil
          end

        end

      end

      describe "#show" do
        context "when there is wanted image" do

          before(:each) do
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
            get :show, :id => '5'
          end

          it { response.should be_success}
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have an image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['image']['name'].should == @image.name
            resp['image']['id'].should == @image.id
            resp['image']['environment'].should == @image.environment
            resp['image']['os'].should == @image.os.name
            resp['image']['arch'].should == @image.os.arch
            resp['image']['os_version'].should == @image.os.version
            resp['image']['description'].should == @image.description
            resp['image']['builds']['build']['id'].should == @build.id
          end
        end

        context "exception should be thrown if image is missing" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :show, :id => '3'
          end

          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "ImageNotFound"
            resp['error']['message'].should == "Could not find Image 3"
          end
        end

        context "when there is NOT wanted image" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :show, :id => '5'
          end

          it { response.should be_not_found}
          it { response.headers['Content-Type'].should include("application/xml") }
        end
      end

      describe "#create" do

        context "exception should be thrown if request is empty" do
          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :create, :id => '3'
          end

          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have error" do
            resp = Hash.from_xml(response.body)
            resp['error']['code'].should == "InsufficientParametersSupplied"
            resp['error']['message'].should == "Please specify a type, build or import"
          end
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
            tpl =%q{<template>
                      <name>Fedora 15 Template</name>
                      <os>
                        <name>Fedora</name>
                        <version>15</version>
                        <arch>x86_64</arch>
                        <install type='url'>
                          <url>http://download.fedoraproject.org/pub/fedora/linux/releases/15/Fedora/x86_64/os/</url>
                        </install>
                        <rootpw>p@ssw0rd</rootpw>
                      </os>
                      <description>A Fedora 15 Image Factory Template</description>
                    </template>}
            xml = Nokogiri::XML::Builder.new do
              image {
                targets "mock"
                tdl {
                  parent.add_child(Nokogiri::XML(tpl).root)
                  target "mock"
                }
                environment "default"
              }
            end
            Aeolus::Image::Factory::Image.stub(:new).and_return(@image)
            Aeolus::Image::Warehouse::Image.stub(:create!).and_return(@image)
            Aeolus::Image::Warehouse::Template.stub(:create!).and_return(@image)
            @image.stub(:targets=).and_return(@image)
            @image.stub(:template=).and_return(@image)
            @image.stub(:save!)
            Aeolus::Image::Factory::TargetImage.stub(:status).and_return(nil)

            request.env['RAW_POST_DATA'] = xml.to_xml
            post :create
          end

          it { response.response_code == 200 }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have an image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['image']['id'].should == @image.id
            resp['image']['build']['target_images'].should == "\n"
            resp['image']['build']['id'].should == @build.id
         end
        end

        context "when trying to import image" do
          before(:each) do
            xml = Nokogiri::XML::Builder.new do
              image {
                target_identifier "tid"
                image_descriptor {
                  child "c1"
                  child "c2"
                }
                provider_account_name "mock"
                environment "default"
              }
            end
            Aeolus::Image::Factory::Image.stub(:new).and_return(@image)
            ProviderAccount.stub(:find_by_label).and_return(@provider_account)
            @provider_account.stub(:provider).and_return(@provider)
            @image.stub(:save!)
            @image.stub(:set_attr)
            # We previously stubbed this out to return nil... That's inappropriate here:
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
            @provider_image.stub(:set_attr)
            @deltacloud_connection = mock("Deltacloud::API")
            @provider_account.stub(:connect).and_return(@deltacloud_connection)
            @deltacloud_image = mock("Deltacloud::API::Stateful::Image",
              :name => 'mock-image')
            @deltacloud_connection.stub(:image).and_return(@deltacloud_image)

            request.env['RAW_POST_DATA'] = xml.to_xml
            post :create
          end
          it { response.response_code == 200 }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should have an image with correct attributes" do
            resp = Hash.from_xml(response.body)
            resp['image']['id'].should == @image.id
            resp['image']['build']['target_images'].should == "\n"
            resp['image']['build']['id'].should == @build.id
         end

        end

        context "when trying to import image that does not exist" do
          before(:each) do
            xml = Nokogiri::XML::Builder.new do
              image {
                target_identifier "tid2"
                image_descriptor {
                  child "c3"
                  child "c4"
                }
                provider_account_name "mock2"
                environment "default"
              }
            end
            Aeolus::Image::Factory::Image.stub(:new).and_return(@image)
            ProviderAccount.stub(:find_by_label).and_return(@provider_account)
            @provider_account.stub(:provider).and_return(@provider)
            @image.stub(:save!)
            @image.stub(:set_attr)
            # We previously stubbed this out to return nil... That's inappropriate here:
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
            @provider_image.stub(:set_attr)
            @deltacloud_connection = mock("Deltacloud::API")
            @provider_account.stub(:connect).and_return(@deltacloud_connection)
            @deltacloud_connection.stub(:image).and_raise("no image")

            request.env['RAW_POST_DATA'] = xml.to_xml
            post :create
          end
          it { response.response_code == 404 }
          it { response.headers['Content-Type'].should include("application/xml") }
          it "should include an error" do
            resp = Hash.from_xml(response.body)
            resp['error']['message'].should == "Could not find Image tid2 on provider"
         end

        end

      end

      describe "#destroy" do
        context "exception should be thrown if image is missing" do

          before(:each) do
            send_and_accept_xml
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
            get :destroy, :id => '3'
          end

          context "response code" do
            subject { response.code.to_i }
            it { should == 404 }
          end
          context "response's Content-Type header" do
            subject { response.headers['Content-Type'] }
            it { should include "application/xml" }
          end
          context "response's body" do
            subject { Hash.from_xml response.body }
            it "should have error" do
              subject['error']['code'].should == "ImageNotFound"
              subject['error']['message'].should == "Could not find Image 3"
            end
          end
        end

        context "when image exists" do
          before(:each) do
            Aeolus::Image::Warehouse::Image.stub(:find).and_return(@image)
          end

          context "and delete succeeds" do
            before(:each) do
              @image.stub(:delete!).and_return(true)
              delete :destroy, :id => @image.id
            end

            it { response.should be_success}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

          context "and delete fails" do
            before(:each) do
              @image.stub(:delete!).and_throw(Exception)

              delete :destroy, :id => @image.id
            end

            it { response.status.should == 500}
            it { response.headers['Content-Type'].should include("application/xml") }
          end

        end

#        context "when image is not found" do
#          before(:each) do
#            Aeolus::Image::Warehouse::Image.stub(:find).and_return(nil)
#            delete :destroy, :id => @image.id
#          end
#
#          it { response.status.should == 404}
#          it { response.headers['Content-Type'].should include("application/xml") }
#        end


      end

    end


    context "when not authenticated" do

      before(:each) do
        mock_warden(nil)
      end

      describe "#index" do

        before(:each) do
          send_and_accept_xml
          get :index
        end

        it "should be unauthorized" do
          response.response_code.should == 401
        end
        it { response.headers['Content-Type'].should include("application/xml") }
      end

      describe "#show" do

        before(:each) do
          send_and_accept_xml
          get :show, :id => '5'
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

      describe "#destroy" do

        before(:each) do
          delete :destroy, :id => '5'
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

    it_behaves_like "Api::ImagesController responding with XML"
  end

  context "XML format responses for Accept: */*" do
    before(:each) do
      accept_all
    end

    it_behaves_like "Api::ImagesController responding with XML"
  end

end
