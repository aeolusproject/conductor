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

require 'spec_helper'

describe ApplicationController do

  fixtures :all

  before(:each) do
    @controller = ApplicationController.new
  end

  context "humanize_error() helper" do
    it "should return a String given an Exception" do
      error = Exception.new('Some arbitrary error')
      human_error = @controller.send(:humanize_error, error)
      human_error.should == "Some arbitrary error"
    end

    it "should consider context in lookup" do
      error = "Connection refused - connect(2)"
      human_error = @controller.send(:humanize_error, error)
      human_error.should == I18n.t('connection_refused')
      human_error2 = @controller.send(:humanize_error, error, :context => :deltacloud)
      human_error2.should == I18n.t('deltacloud.unreachable')
    end

  end
end
