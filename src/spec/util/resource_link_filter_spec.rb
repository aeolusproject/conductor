#
#   Copyright 2012 Red Hat, Inc.
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

describe ResourceLinkFilter do

  describe "#transform_resource_links" do

    before do
      @controller = stub({
        :request => stub({
          :format => :xml
        })
      })
      @controller.stub(:params).and_return(params)
    end

    context "successful transformation" do

      before do
        ResourceLinkFilter.new(resource_links).before(@controller)
      end

      context "for a simple link" do
        let(:params) do {
            :catalog => {
              :id => 123
            }
          }
        end
        let(:resource_links) { :catalog }

        it "transforms the link" do
          params[:catalog].should == nil
          params[:catalog_id].should == 123
        end
      end

      context "for a nested link" do
        let(:params) do
          {
            :catalog => {
              :pool => {
                :id => 123
              }
            }
          }
        end
        let(:resource_links) { { :catalog => :pool } }

        it "transforms the link" do
          params[:catalog][:pool].should == nil
          params[:catalog][:pool_id].should == 123
        end
      end

      context "for multiple nested links" do
        let(:params) do
          {
            :catalog => {
              :pool => {
                :id => 123
              },
              :something => {
                :id => 456
              }
            }
          }
        end
        let(:resource_links) { { :catalog => [:pool, :something] } }

        it "transforms the links" do
          params[:catalog][:pool].should == nil
          params[:catalog][:pool_id].should == 123
          params[:catalog][:something].should == nil
          params[:catalog][:something_id].should == 456
        end
      end

      context "for combined single- and double-nested links" do
        let(:params) do
          {
            :catalog => {
              :pool => {
                :id => 123
              },
              :something => {
                :double_nested_1 => {
                  :id => 456
                },
                :double_nested_2 => {
                  :id => 789
                }
              }
            }
          }
        end
        let(:resource_links) do
          {
            :catalog => [
              :pool,
              { :something => [:double_nested_1, :double_nested_2] }
            ]
          }
        end

        it "transforms the links" do
          params[:catalog][:pool].should == nil
          params[:catalog][:pool_id].should == 123
          params[:catalog][:something][:double_nested_1].should == nil
          params[:catalog][:something][:double_nested_1_id].should == 456
          params[:catalog][:something][:double_nested_2].should == nil
          params[:catalog][:something][:double_nested_2_id].should == 789
        end
      end

    end

    context "when missing 'id' attribute in the link" do
      let(:params) do
        {
          :catalog => {}
        }
      end
      let(:resource_links) { :catalog }

      it "does not transform anything" do
        params[:catalog].should == {}
        params[:catalog_id].should == nil
      end
    end

    context "when missing the whole link" do
      let(:params) { {} }
      let(:resource_links) { :catalog }

      it "does not transform anything" do
        params[:catalog].should == nil
        params[:catalog_id].should == nil
      end
    end

    context "when not XML request" do
      let(:params) { {} }

      before do
        @controller.stub_chain(:request, :format).and_return(:html)
      end

      it "does not touch params" do
        @controller.should_not_receive(:params)
        ResourceLinkFilter.new(:something).before(@controller)
      end
    end

  end

end
