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

describe ApplicationHelper do
  include ApplicationHelper

  context "restful_submit_tag() helper" do

    it "contains mapping as hidden fields" do
      html = restful_submit_tag('Delete', 'destroy', 'destroy_url', 'DELETE')
      doc = Nokogiri::HTML(html)
      nodes = (doc/"input[@type='hidden']")

      nodes.each do |node|
        ['__map[destroy][url]', '__map[destroy][method]'].include?(node['name']).should be_true
      end
    end

    it "with no options" do
      html = restful_submit_tag('Delete', 'destroy', 'destroy_url', 'DELETE')
      doc = Nokogiri::HTML(html)
      node = (doc/"input[@type='submit']")

      node.first['name'].should == '__rewrite[destroy]'
    end

    it "with options" do
      html = restful_submit_tag('Delete', 'destroy', 'destroy_url', 'DELETE', :id => 'delete', :name => 'test')
      doc = Nokogiri::HTML(html)
      node = (doc/"input[@type='submit']")

      node.first['name'].should == '__rewrite[destroy]'
      node.first['id'].should == 'delete'
    end

    it "count_uptime should return right values" do
      count_uptime(Time.now-(Time.now-10)).should be_true
    end

    it "count_uptime should return N/A if nil is passed as parameter" do
      count_uptime(nil).should == "N/A"
    end

  end

end
