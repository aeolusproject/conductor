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

require "spec_helper"

describe Credential do
  before(:each) do
    @credential = Factory.build(:credential)
  end

  it "default factory object is valid" do
    @credential.should be_valid
  end

  it "should not be valid without value" do
    @credential.value = nil
    @credential.should_not be_valid
  end

  it "should not be valid without assigned credential definition" do
    @credential.credential_definition_id = nil
    @credential.should_not be_valid
  end

  it "should not be valid without unique credential definition" do
    @credential.save!
    @second_credential = Factory.build(:credential,
                                       :credential_definition_id => @credential.credential_definition_id,
                                       :provider_account_id => @credential.provider_account_id)
    @second_credential.should_not be_valid
  end
end
