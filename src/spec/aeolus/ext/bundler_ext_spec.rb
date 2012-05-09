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
require 'bundler_ext_helper'

module Aeolus
  module Ext
    describe BundlerExt do
      before(:each) do
	@gemfile = 'spec/fixtures/Gemfile.in'
      end

      describe "#parse_from_gemfile" do
        describe "with no group passed in" do
          it "should return the list of system libraries in the :default group to require" do
            libs = BundlerExt.parse_from_gemfile(@gemfile)
	    libs.should be_an(Array)
	    libs.should include('deltacloud')
	    libs.should_not include('vcr')
          end
        end
        describe "with group passed in" do
          it "should not return any deps that are not in the 'development' group" do
            libs = BundlerExt.parse_from_gemfile(@gemfile,'development')
            libs.should be_an(Array)
	    libs.should_not include('deltacloud')
          end
          it "should return only deps that are in the :test group" do
            libs = BundlerExt.parse_from_gemfile(@gemfile, :test)
            libs.should be_an(Array)
	    libs.should_not include('deltacloud')
	    libs.should include('vcr')
	  end
          it "should return deps from both the :default and :test groups" do
            libs = BundlerExt.parse_from_gemfile(@gemfile, :default, :test)
            libs.should be_an(Array)
	    libs.should include('deltacloud')
	    libs.should include('vcr')
	  end
        end
        it "should only return deps for the current platform" do
          libs = BundlerExt.parse_from_gemfile(@gemfile)
          libs.should be_an(Array)
	  if RUBY_VERSION < "1.9"
	    libs.should_not include('cinch')
	  else
	    libs.should_not include('fastercsv')
          end
        end
      end
      describe "#system_require" do
        it "should load the libraries in the gemfile" do
          BundlerExt.system_require(@gemfile)
          Object.const_defined?(:DeltaCloud).should be_true
        end
        it "should load the libraries in the gemfile" do
          BundlerExt.system_require(@gemfile, :fail)
	  Object.const_defined?(:DeltaCloud).should be_true
        end
      end
    end
  end
end
