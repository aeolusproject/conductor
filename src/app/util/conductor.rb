#
#   Copyright 2011 Red Hat, Inc.
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

require 'i18n'

def gb_to_kb(val_in_gigs)
  return nil if nil_or_empty(val_in_gigs)
  return val_in_gigs.to_i * 1024 * 1024
end

def kb_to_gb(val_in_kb)
  return nil if nil_or_empty(val_in_kb)
  return val_in_kb.to_i / 1024 / 1024
end
def mb_to_kb(val_in_mb)
  return nil if nil_or_empty(val_in_mb)
  return val_in_mb.to_i * 1024
end

def kb_to_mb(val_in_kb)
  return nil if nil_or_empty(val_in_kb)
  return val_in_kb.to_i / 1024
end

def nil_or_empty(val)
  if val.nil? or (val.kind_of?(String) and val.empty?)
    return true
  else
    return false
  end
end

# Try to clean up and internationalize certain errors we get from other components
# Accepts a string or an Exception
def humanize_error(error, options={})
  error = error.message if error.is_a?(Exception)
  if error.match("Connection refused - connect\\(2\\)")
    if options[:context] == :deltacloud
        return I18n.translate('deltacloud.unreachable')
    else
      return I18n.translate('connection_refused')
    end
  else
    # Nothing else matched
    error
  end
end

# Find a class for CSV generation
def get_csv_class
   return FasterCSV if Object.const_defined?(:FasterCSV)
   Object.const_defined?(:CSV) or require 'csv'
   CSV
end
