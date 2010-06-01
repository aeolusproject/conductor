#
# Copyright (C) 2009 Red Hat, Inc.
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

module ApplicationHelper

  def confirmation_dialog(div_id, text, action)
    %{
      <div id="#{div_id}" style="display:none;">
        <div class="confirm_dialog_title">
          <div class="confirm_dialog_header">#{text}</div>
          <div style="clear:both;"></div>
        </div>

        <div class="confirm_dialog_footer">
          <div class="button">
            <div class="button_left_grey"></div>
            <div class="button_middle_grey"><a href="#" onclick="$(document).trigger('close.facebox')">Cancel</a></div>
            <div class="button_right_grey"></div>
          </div>
          <div class="button">
            <div class="button_left_blue"></div>
            <div class="button_middle_blue"><a href="#" onclick="#{action}">OK</a></div>
            <div class="button_right_blue"></div>
          </div>
        </div>
      </div>
     }
  end

  def number_to_duration(input_num)
    input_int = input_num.to_i
    hours_to_seconds = [input_int/3600 % 24,
                        input_int/60 % 60,
                        input_int % 60].map{|t| t.to_s.rjust(2,'0')}.join(':')
    days = input_int / 86400
    day_str = ""
    if days > 0
      day_label = (days > 1) ? "days" : "day"
      day_str = "#{days} #{day_label} "
    end
    day_str + hours_to_seconds
  end
end
