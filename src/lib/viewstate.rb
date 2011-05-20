module ActionController
  class Base
    class << self
      attr_accessor :default_viewstates
      def viewstate(action, &block)
        action = action.to_s
        self.default_viewstates ||= {}
        self.default_viewstates[action] = block

        setup_viewstate_routes(action)
        before_filter :handle_viewstate, :only => [action]
      end

      def setup_viewstate_routes(action)
        self.send(:define_method, :get_viewstate)  { get_viewstate_body(action) }
        self.send(:define_method, :put_viewstate) { put_viewstate_body(action) }
        self.send(:define_method, :post_viewstate) { post_viewstate_body(action) }
        self.send(:define_method, :delete_viewstate) { delete_viewstate_body(action) }

        route_url = "#{controller_name}/#{action}/viewstate/:id"
        return if ActionController::Routing::Routes.routes.any? {|r| r.to_s.include? route_url }

        get_viewstate_route = ActionController::Routing::Routes.builder.build(route_url,
                                                                              :controller => controller_name,
                                                                              :action => 'get_viewstate',
                                                                              :conditions => {:method => :get})
        ActionController::Routing::Routes.routes.insert(0, get_viewstate_route)

        put_viewstate_route = ActionController::Routing::Routes.builder.build(route_url,
                                                                              :controller => controller_name,
                                                                              :action => 'put_viewstate',
                                                                              :conditions => {:method => :put})
        ActionController::Routing::Routes.routes.insert(0, put_viewstate_route)

        post_viewstate_route = ActionController::Routing::Routes.builder.build(route_url,
                                                                              :controller => controller_name,
                                                                              :action => 'post_viewstate',
                                                                              :conditions => {:method => :post})
        ActionController::Routing::Routes.routes.insert(0, post_viewstate_route)

        delete_viewstate_route = ActionController::Routing::Routes.builder.build(route_url,
                                                                                :controller => controller_name,
                                                                                :action => 'delete_viewstate',
                                                                                :conditions => {:method => :delete})
        ActionController::Routing::Routes.routes.insert(0, delete_viewstate_route)
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

    def viewstate
      if viewstate_given?
        if vs = find_viewstate(params[:viewstate])
          @viewstate = vs
        else
          @viewstate = create_viewstate
        end
      else
        if vs = session_viewstate
          @viewstate = vs
        else
          @viewstate = create_viewstate
        end
      end
      set_session_viewstate(@viewstate)
      @viewstate.state
    end

    def handle_viewstate
      viewstate
      if viewstate_modified?
        @viewstate.state = @viewstate.state.merge(viewstate_params)
      end

      return unless (viewstate_given? or viewstate_modified?)

      if @viewstate and not viewstate_given?
        params[:viewstate] = @viewstate.id
        redirect_to params and return
      end
    end

    def viewstate_given?
      params.include? 'viewstate'
    end

    def viewstate_modified?
      not viewstate_params.empty?
    end

    def viewstate_params
      params.reject {|k,v| ['controller', 'action', '_method', 'viewstate'].include? k}
    end
  end
end
