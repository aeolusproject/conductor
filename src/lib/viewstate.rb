module ActionController
  class Base
    class << self
      attr_accessor :default_viewstates
      def viewstate(action, &block)
        action = action.to_s
        self.default_viewstates ||= {}
        self.default_viewstates[action] = block

        setup_viewstate_handlers
        setup_viewstate_routes(action)
      end

      def setup_viewstate_handlers
        unless self.before_filter.include? :handle_viewstate
          before_filter :handle_viewstate, :only => self.default_viewstates.keys
        else
          # Don't append a new filter; update the existing one instead
          filter_index = self.before_filter.index :handle_viewstate
          filter = self.before_filter[filter_index]
          filter.options[:only] = Set.new(self.default_viewstates.keys)
        end
      end

      def setup_viewstate_routes(action)
        @@viewstate_routes ||= []
        self.send(:define_method, "get_viewstate_#{action}")  { get_viewstate_body(action) }
        self.send(:define_method, "put_viewstate_#{action}") { put_viewstate_body(action) }
        self.send(:define_method, "post_viewstate_#{action}") { post_viewstate_body(action) }
        self.send(:define_method, "delete_viewstate_#{action}") { delete_viewstate_body(action) }

        route_url = "#{controller_name}/#{action}/viewstate(/:id)"
        routes = Conductor::Application.routes.routes
        return if routes.any? {|r| r.to_s.include? route_url }

        [:get, :put, :post, :delete].each do |method|
        @@viewstate_routes << { :url => route_url, :method => method,
          :controller => controller_name, :action => "#{method}_viewstate_#{action}" }
        end
        @@viewstate_routes.uniq!

        begin
          route_set = Conductor::Application.routes
          route_set.disable_clear_and_finalize = true
          route_set.clear!
          route_set.draw do
            @@viewstate_routes.each do |route|
              match(route[:url], :via => route[:method],
                    :controller => route[:controller],
                    :action => route[:action])
            end
          end
          Conductor::Application.routes_reloader.paths.each { |path| load(path) }
          ActiveSupport.on_load(:action_controller) { route_set.finalize! }
        ensure
          route_set.disable_clear_and_finalize = false
        end
      end
    end

    def get_viewstate_body(action)
      viewstate = find_viewstate(params[:id], action)
      render :json => viewstate ? viewstate.state : {}
    end

    def put_viewstate_body(action)
      viewstate = find_viewstate(params[:id], action)
      if viewstate
        viewstate.state = viewstate.state.merge(viewstate_params)
        if viewstate.find_by_uuid(viewstate.uuid)
          viewstate.save!
        end
      end

      render :json => viewstate ? viewstate.state : {}
    end

    def post_viewstate_body(action)
      viewstate = session_viewstate(action)
      if viewstate.name = params[:name]
        viewstate.save!
        render :text => viewstate.uuid, :status => 201
      else
        render :text => 'ViewState name must be specified', :status => 409
      end
    end

    def delete_viewstate_body(action)
      if saved_viewstate = ViewState.find_by_uuid(params[:id])
        saved_viewstate.destroy
      end

      viewstate = create_viewstate(action)
      set_session_viewstate(viewstate, action)

      render :json => viewstate.state
    end

    def find_viewstate(uuid=nil, action=nil)
      vs = session_viewstate(action)
      unless uuid.nil? or vs.uuid == uuid
          vs = ViewState.find_by_uuid(uuid)
      end

      return vs
    end

    def session_viewstate_key(action=nil, controller=nil)
      action ||= action_name
      controller ||= controller_name
      [controller, action].join '#'
    end

    def session_viewstate(action=nil)
      session[:viewstates] ||= {}
      session[:viewstates][session_viewstate_key(action)]
    end

    def set_session_viewstate(value, action=nil)
      session[:viewstates] ||= {}
      session[:viewstates][session_viewstate_key(action)] = value
    end

    def create_viewstate(action=nil)
      action ||= action_name
      default_state = {}
      self.class.default_viewstates[action].call(default_state)
      result = ViewState.new(:action => action, :controller => controller_name,
                             :state => default_state, :user_id => current_user.id)
      result.uuid = UUIDTools::UUID.timestamp_create.to_s
      result
    end

    def handle_viewstate
      if viewstate_given?
        @viewstate = (find_viewstate(params[:viewstate]) or create_viewstate)

        @viewstate.uuid = params[:viewstate]
        @viewstate.state = @viewstate.state.merge(viewstate_params)
        set_session_viewstate(@viewstate)
      elsif viewstate_modified?
        @viewstate = (find_viewstate or create_viewstate)

        @viewstate.state = @viewstate.state.merge(viewstate_params)
        set_session_viewstate(@viewstate)

        respond_to do |format|
          format.html do
            params[:viewstate] = @viewstate.id
            redirect_to params
          end
          format.js { }
        end
      else
        @viewstate = nil
      end
    end

    def viewstate_given?
      params.include? 'viewstate'
    end

    def viewstate_modified?
      not viewstate_params.empty?
    end

    def viewstate_params
      params.reject {|k,v| ['controller', 'action', 'id', '_method', 'viewstate'].include? k}
    end

    def viewstate_id
      @viewstate ? @viewstate.id : nil
    end
  end
end
