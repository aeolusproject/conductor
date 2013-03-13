old_fast_gettext = !defined?(FastGettext::Version) ||
  # compare versions x.x.x <= 0.6.7
  (FastGettext::Version.split('.').map(&:to_i) <=> [0, 6, 8]) == -1

FastGettext.add_text_domain('app', {
  :path => File.expand_path("../../../locale", __FILE__),
  :type => :po,
  :ignore_fuzzy => true
}.update(old_fast_gettext ? { :ignore_obsolete => true } : { :report_warning => false }))

FastGettext.default_available_locales = ['en']

FastGettext.default_text_domain = 'app'