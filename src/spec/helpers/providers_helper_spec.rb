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

describe ProvidersHelper do
  include ProvidersHelper

  context "edit_button() helper" do

    it "formats link with path to edit action if rendered in show or accounts action" do
      provider = FactoryGirl.create(:mock_provider)

      edit_button(provider, 'show').should =~ /providers\/[0-9]*\/edit/
    end

    it "formats blank link with no action and with disabled class if not in show or accounts action" do
      provider = FactoryGirl.create(:mock_provider)

      edit_button = edit_button(provider, 'index')
      edit_button.should =~ /href="#"/
      edit_button.should =~ /disabled/
    end

  end

end
