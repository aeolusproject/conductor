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

describe CredentialDefinition do
  before(:each) do
    @cred_def = Factory.build(:credential_definition)
  end

  it "default factory object should be valid" do
    @cred_def.should be_valid
  end


  it "should not be valid without name" do
    @cred_def.name = nil
    @cred_def.should_not be_valid
  end

  it "should not be valid without label" do
    @cred_def.label = nil
    @cred_def.should_not be_valid
  end

end
