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

describe ApplicationController do

  fixtures :all

  before(:each) do
    @controller = ApplicationController.new
  end

  context "humanize_error() helper" do
    it "should return a String given an Exception" do
      error = Exception.new('Some arbitrary error')
      human_error = @controller.send(:humanize_error, error)
      human_error.should == "Some arbitrary error"
    end

    it "should consider context in lookup" do
      error = "Connection refused - connect(2)"
      human_error = @controller.send(:humanize_error, error)
      human_error.should == I18n.t('connection_refused')
      human_error2 = @controller.send(:humanize_error, error, :context => :deltacloud)
      human_error2.should == I18n.t('deltacloud.unreachable')
    end

  end
end
