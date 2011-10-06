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

describe ProvidersController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :provider_admin_permission
    @provider = @admin_permission.permission_object
    @admin = @admin_permission.user
    mock_warden(@admin)
  end

  describe "provide ui to view realms" do
    before do
      get :show, :id => @provider.id, :details_tab => 'realms', :format => :js
    end

    it { response.should be_success }
    it { assigns[:realm_names].size.should == @provider.realms.size }
    it { response.should render_template(:partial => "providers/_realms") }
  end
end
