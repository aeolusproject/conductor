# This is a (hopefully) temporary workaround to help
# mongrel, since it hooks into the now-gone AbstractRequest
# class.  We should test if this issue occurs with thin
# webserver, perhaps we can use that instead of mongrel
# and drop this altogether.  Set only to production, otherwise
# it kills our test suite.

config = Rails::Configuration.new
if config.environment == 'production'
  module ActionController
    class AbstractRequest < ActionController::Request
      def self.relative_url_root=(path)
        ActionController::Base.relative_url_root=(path)
      end
      def self.relative_url_root
        ActionController::Base.relative_url_root
      end
    end
  end
end
