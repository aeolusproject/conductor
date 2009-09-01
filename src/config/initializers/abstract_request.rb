#This is a (hopefully) temporary workaround to help
#mongrel, since it hooks into the now-gone AbstracRequest
#class.

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
