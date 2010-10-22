module TemplatesHelper
  class ButtonPaginationRenderer < WillPaginate::LinkRenderer
    def page_link(page, text, attributes = {})
      #submit_tag text, :name => 'page'
      "<input type=submit value='#{text}' name='page'/>"
    end
  end
end
