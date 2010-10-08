# Copyright (C) 2010 Red Hat, Inc.
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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module DashboardHelper

  def monitor_quota_value(name, value, unit)
    name=content_tag 'td', :class => 'first nowrap' do
      name
    end
    value=content_tag 'td', :class => 'graph' do
      content_tag 'div', :class => 'percentBlock' do
        value
      end
    end
    unit=content_tag 'td' do
      unit
    end
    "#{name}#{value}#{unit}"
  end

  def monitor_bar_value(value, opts={})
    bar=content_tag 'td', :class => "graph" do
      percent_block=content_tag 'div', :class => 'percentBlock' do
        # TODO: Count text-indent value correctly here
        bar_style = "width:#{value}%;text-indent:14%"
        content_tag 'div', :class => 'percentBlockInner good', :style => bar_style do
          "#{value}%"
        end
      end
      if opts[:min] and opts[:max]
        min=content_tag 'div', :class => 'min' do "#{opts[:min]}% Min" ; end
        max=content_tag 'div', :class => 'max' do "#{opts[:max]}% Max" ; end
        "#{percent_block}#{min}#{max}"
      else
        percent_block
      end
    end
    total=content_tag 'td' do
      "#{opts[:total]}"
    end
    "#{bar}#{total}"
  end


end
