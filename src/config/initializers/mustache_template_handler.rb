module MustacheTemplate

  class Handler
    def self.erb_handler
      @@erb_handler ||= ActionView::Template.registered_template_handler(:erb)
    end

    def self.call(template)
      compiled_erb_template = erb_handler.call(template).gsub(/'/, "\\\\'")
      "MustacheTemplate::View.new(self, '#{compiled_erb_template}').render.html_safe"
    end
  end

  class View
    def initialize(view_context, compiled_erb_template)
      @view_context = view_context
      @template_source = evaluate_rails_helpers(compiled_erb_template)
    end

    def render
      renderer =
        if Rails.version >= '3.1'
          @view_context.instance_variable_get('@view_renderer').instance_variable_get('@_partial_renderer')
        else
          @view_context.instance_variable_get('@renderer') if @view_context.instance_variable_names.include?('@renderer')
        end

      options = renderer.instance_variable_get("@options") if renderer

      if options && options.include?(:mustache)
        Mustache.render(@template_source, options[:mustache]).html_safe
      else
        @template_source.html_safe
      end
    end

    private

    def evaluate_rails_helpers(compiled_erb_template)
      @view_context.instance_eval do
        eval(compiled_erb_template)
      end
    end
  end


end

ActionView::Template.register_template_handler :mustache, MustacheTemplate::Handler
