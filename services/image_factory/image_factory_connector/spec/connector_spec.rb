#
# Copyright (C) 2011 Red Hat, Inc.
# Written by Jason Guiditta <jguiditt@redhat.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.  A copy of the GNU General Public License is
# also available at http://www.gnu.org/copyleft/gpl.html.

require 'spec_helper'

#set :environment, :test

describe 'image_factory_connector app' do
  class BuildAdaptor
    attr_accessor :image_id
  end

  def app
    ImageFactoryConnector
  end

  before(:each) do
    @b= BuildAdaptor.new
    @b.image_id ="00bf4ee5-39f8-4cc6-95bd-7ca42b1c1d5f"
  end

  it 'gets an agent' do
    get '/'
    last_response.should be_ok
    last_response.body.should == app.console.q.to_s
  end

  it "sends status updates to the conductor" do
    post 'build', {:template => '<template></template>', :target => 'mock'}
    #app.console.handler.should_receive(:handle_status).at_least(1).times
  end

  # TODO: clean up these xml checks so they are in some fixture (or similar) and not repeated
  it 'calls the console build_image method and returns xml response with uuid' do
    app.console.stub!(:build_image).and_return(@b)
    post 'build', {:template => '<template></template>', :target => 'mock'}
    last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<image>\n  <uuid>#{@b.image_id}</uuid>\n</image>\n"
  end

  it 'calls the console push_image method and returns xml response with uuid' do
    app.console.stub(:push_image).and_return(@b)
    post 'push', {:image_id => @b.image_id, :provider => 'mock', :credentials => 'some creds'}
    last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<image>\n  <uuid>#{@b.image_id}</uuid>\n</image>\n"
  end

  context "returns errors if missing params" do
    it "returns a single error" do
      post 'build', {:template => '', :target => 'mock'}
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>Missing template</error>\n"
    end

    it "returns a multiple errors" do
      post 'push', {:image_id => @b.image_id, :provider => '', :credentials => ''}
      last_response.body.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<error>Missing credentials</error>\n<error>Missing provider</error>\n"
    end
  end

  it 'closes the connection' do
    get 'shutdown'
    last_response.should be_ok
    last_response.body.should == "Console connection closed"
  end

end
