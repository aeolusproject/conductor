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

if defined? String::INTERPOLATION_PATTERN and defined? String::INTERPOLATION_PATTERN_WITH_ESCAPE
  class String

    # see https://bugzilla.redhat.com/show_bug.cgi?id=830713
    #
    # related files:
    #   i18n-0.5.0/lib/i18n/core_ext/string/interpolate.rb:86
    #   fast_gettext-0.6.4/lib/fast_gettext/vendor/string.rb:18

    def _fast_gettext_old_format_m(args)
      if args.kind_of?(Hash)
        dup.gsub(INTERPOLATION_PATTERN_WITH_ESCAPE) do |match|
          if match == '%%'
            '%'
          else
            match =~ INTERPOLATION_PATTERN # this line is added to fill $1 and $2
            key = ($1 || $2).to_sym
            raise KeyError unless args.has_key?(key)
            $3 ? sprintf("%#{$3}", args[key]) : args[key]
          end
        end
      elsif self =~ INTERPOLATION_PATTERN
        raise ArgumentError.new('one hash required')
      else
        result = gsub(/%([{<])/, '%%\1')
        result.send :'interpolate_without_ruby_19_syntax', args
      end
    end
  end
end