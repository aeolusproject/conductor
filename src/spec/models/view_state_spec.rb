#
# Copyright (C) 2011 Red Hat, Inc.
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

describe ViewState do

  before(:each) do
    @view_state = FactoryGirl.create :view_state
  end

  it "should require a unique name" do
    vs = Factory.build :view_state, :name => nil
    vs.should_not be_valid

    vs.name = @view_state.name
    vs.should_not be_valid

    vs.name = "a nice unique name"
    vs.should be_valid
  end

  it "should require a controller and action" do
    @view_state.controller = nil
    @view_state.should_not be_valid

    @view_state.controller = "deployments"
    @view_state.should be_valid

    @view_state.action = nil
    @view_state.should_not be_valid

    @view_state.action = "view"
    @view_state.should be_valid
  end

  it "should require a non-empty state" do
    @view_state.state = nil
    @view_state.should_not be_valid

    @view_state.state = {}
    @view_state.should_not be_valid

    @view_state.state = {:a => 1}
    @view_state.should be_valid
  end

  it "should be associated to a user" do
    @view_state.user_id = nil
    @view_state.should_not be_valid

    user = FactoryGirl.create :user
    @view_state.user_id = user.id
    @view_state.should be_valid
  end

  it "should provide an access to the key-value attributes" do
    @view_state.state.should eql({'sort-column' => 'name', 'sort-order' => 'desc',
                                       'columns' => ['name', 'deployments', 'instances']})
  end

  it "should allow setting the key-value attributes" do
    custom_attributes = {'a' => 1, 'b' => 2, 'nested' => {'x' => 'hello', 'y' => 'world'} }
    @view_state.state = custom_attributes
    @view_state.save!

    @view_state.state.should eql(custom_attributes)
    ViewState.find(@view_state).state.should eql(custom_attributes)
  end

  it "should not save attributes that are only relevant in a user session" do
    session_state = { 'sort-column' => 'name', 'page' => 3 }
    @view_state.state = session_state
    @view_state.state.should eql(session_state)
    @view_state.save!

    expected_saved_state = {'sort-column' => 'name'}
    @view_state.state.should eql(expected_saved_state)
    ViewState.find(@view_state).state.should eql(expected_saved_state)
  end

end
