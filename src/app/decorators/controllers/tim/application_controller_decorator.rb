Tim::ApplicationController.class_eval do
  layout 'layouts/application'

  respond_to :js, :html, :xml
end
