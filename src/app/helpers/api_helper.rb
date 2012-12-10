#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module ApiHelper

  # Serializes into http://www.w3.org/TR/xmlschema-2/#dateTime
  # e.g. "2012-11-05T09:15:53+01:00"
  def xmlschema_datetime(datetime)
    datetime.strftime('%FT%H:%M:%%s%:z') %
      xmlschema_seconds_string(datetime.strftime('%S.%N'))
  end

  # Serializes into http://www.w3.org/TR/xmlschema-2/#duration
  # e.g. "P432D14H34M45.023S"
  # Uses units only upto days, because bigger units (months, years) are
  # ambiguous). Always prints days, hours, minutes and seconds, even though
  # the standard allows ommiting.
  def xmlschema_absolute_duration(total_seconds)
    seconds_in_day = 86400
    seconds_in_hour = 3600
    seconds_in_minute = 60

    days, seconds_minus_days = total_seconds.abs.divmod(seconds_in_day)
    hours, seconds_minus_hours = seconds_minus_days.divmod(seconds_in_hour)
    minutes, seconds = seconds_minus_hours.divmod(seconds_in_minute)

    time = ''
    time << '-' if total_seconds < 0
    time << 'P' <<
            '%iD' % days <<
            'T' <<
            '%iH' % hours <<
            '%iM' % minutes <<
            '%sS' % xmlschema_seconds_string(seconds.to_s)
  end

  private

  # Takes a string specifying number of seconds (e.g. "04.2500") and converts
  # the decimal part of the string so that it is valid in XML Schema
  # datetime/duration representation (e.g. "04.25"). Does not touch the part
  # that specifies whole seconds (leading zeros are preserved).
  #
  # That means:
  # * if decimal part is zero, it must not be printed at all
  # * decimal part must not have trailing zeros
  def xmlschema_seconds_string(seconds_string)
    fixed_string = seconds_string
    # if the decimal part is zero(s), it must be removed completely
    fixed_string.gsub!(/\.0*\Z/, '')
    # even if decimal part is nonzero, trailing zeros are not allowed
    fixed_string.gsub!(/0*\Z/, '') if seconds_string.include?('.')

    fixed_string
  end
end
