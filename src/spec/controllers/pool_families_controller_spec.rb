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

describe PoolFamiliesController do

  fixtures :all
  before(:each) do
    @admin_permission = FactoryGirl.create :admin_permission
    @admin = @admin_permission.user
    @user_permission = FactoryGirl.create :pool_user_permission
    @user = @user_permission.user
  end

  it "should allow authorized users to create pool family" do
    mock_warden(@admin)
    lambda do
     post :create, :pool_family => {
       :name => 'test',
       :quota_attributes => { :maximum_running_instances => nil },
     }
    end.should change(PoolFamily, :count).by(1)
    PoolFamily.find_by_name('test').should_not be_nil
    response.should redirect_to(pool_families_path)
  end

  it "should prevent unauthorized users from creating pool families" do
    mock_warden(@user)
    lambda do
     post :create, :pool_family => {
       :name => 'test',
       :quota_attributes => { :maximum_running_instances => nil },
     }
    end.should_not change(PoolFamily, :count)
    response.should render_template('layouts/error')
  end

  it "should allow authorized users to edit pool family" do
    pool_family = FactoryGirl.create :pool_family
    mock_warden(@admin)
    put :update, :id => pool_family.id, :pool_family => {
      :name => 'updated pool family',
      :quota_attributes => { :maximum_running_instances => 10 },
    }
    PoolFamily.find_by_name('updated pool family').should_not be_nil
    response.should redirect_to(pool_families_path)
  end

  it "should prevent unauthorized users from creating pool families" do
    pool_family = FactoryGirl.create :pool_family
    mock_warden(@user)
    put :update, :id => pool_family.id, :pool_family => {
      :name => 'updated pool family',
      :quota_attributes => { :maximum_running_instances => 10 },
    }
    PoolFamily.find_by_name('updated pool family').should be_nil
    response.should render_template('layouts/error')
  end
end
