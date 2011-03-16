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
require 'typhoeus'

class FakeData < Hash
  attr_accessor :event, :new_status
  def initialize(args={})
    self.event = args[:event]
    self.new_status = args[:new_status].downcase
  end
end

describe "factory_rest_handler" do
  before(:each) do
    @l = Logger.new(STDOUT)
    @l.level = Logger::DEBUG
    @handler=FactoryRestHandler.new(@l)
    @image_id ="71c852f5-de8f-467a-81db-eedb72c5ec8b"
    @fd=FakeData.new({:event=>"STATUS", :new_status=>"FUBAR"})
    @fd["addr"]={"_object_name"=>"build_adaptor:image:#{@image_id}"}
  end

  it "parses the event properly" do
    e=@handler._process_event(@fd)
    e.event.should == @fd.event
    e.value.should == @fd.new_status
    e.uuid.should == @image_id
    e.obj.should == "image"
  end

  it "sends status updates to the conductor" do
    # TODO: properly stub this out
    #@handler.handle_status(@fd)
  end

  it "handles failure when updating the conductor" do
    @fd["addr"]={"_object_name"=>"build_adaptor:image:some-bogus-uuid"}
    @handler.handle_status(@fd)
  end
end