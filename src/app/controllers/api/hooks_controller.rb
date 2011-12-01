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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Api
  class HooksController < ApplicationController
    before_filter :require_user_api
    rescue_from ActiveRecord::RecordNotFound, :with => :not_found

    respond_to :xml
    layout :false

    def index
      @hooks = Hook.all
      respond_with(@hooks)
    end

    def show
      @hook = Hook.find(params[:id])
      respond_with(@hook)
    end

    def create
      unless params[:hook]
        head :status => 400 and return
      end

      version = params[:hook][:version]
      unless version == '1'
        head :status => 501 and return
      end

      @hook = Hook.new params[:hook]
      if @hook.save
        render 'show', :status => :created, :location => api_hook_url(@hook)
      else
        head :status => 400
      end
    end

    def destroy
      hook = Hook.find(params[:id])

      if hook.destroy
        head :status => 204
      else
        head :status => 500
      end
    end

    private
    def not_found
      head :status => :not_found
    end

  end
end
