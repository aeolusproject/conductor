module LegacyTemplatesHelper
  class ButtonPaginationRenderer < WillPaginate::LinkRenderer
    def page_link(page, text, attributes = {})
      #submit_tag text, :name => 'page'
      "<input type=submit value='#{text}' name='page' class='#{attributes[:class]}' />"
    end
  end
end
