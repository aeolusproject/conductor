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

describe Realm do

  before(:each) do
    @provider = FactoryGirl.create :mock_provider
    @backend_realm = FactoryGirl.create :backend_realm, :provider => @provider

    @frontend_realm1 = FactoryGirl.create :frontend_realm
    RealmBackendTarget.create!(:frontend_realm => @frontend_realm1, :realm_or_provider => @backend_realm)
    RealmBackendTarget.create!(:frontend_realm => @frontend_realm1, :realm_or_provider => @provider)
  end

  it "should validate backend" do
    @backend_realm.provider_id.should_not be_nil
    @backend_realm.frontend_realms.should_not be_empty
    @backend_realm.frontend_realms.first.id.should == @frontend_realm1.id
    @provider.frontend_realms.should_not be_empty
    @provider.frontend_realms.first.id.should == @frontend_realm1.id
  end

  it "should validate frontend" do
    @frontend_realm1.backend_realms.should_not be_empty
    @frontend_realm1.backend_realms.first.id.should == @backend_realm.id
    @frontend_realm1.backend_providers.should_not be_nil
    @frontend_realm1.backend_providers.first.id.should == @provider.id
  end

  it "should delete a provider from backend target when the provider is deleted" do
    @backend_realm.destroy
    @frontend_realm1.backend_realms.should be_empty
    @provider.destroy
    @frontend_realm1.realm_backend_targets.should be_empty
  end

  it "should delete backend targets when frontend realm is deleted" do
    @frontend_realm1.destroy
    RealmBackendTarget.all(:conditions => {:frontend_realm_id => @frontend_realm1.id}).should be_empty
  end

end
