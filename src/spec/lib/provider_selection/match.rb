#
#   Copyright 2012 Red Hat, Inc.
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

describe ProviderSelection::Match do

  it "nil score should worth more than any defined score" do
    match_with_assigned_score = ProviderSelection::Match.new(:provider_account => nil, :score => 0)
    match_with_nil_score = ProviderSelection::Match.new(:provider_account => nil)
    match_with_assigned_score.calculated_score.should be < match_with_nil_score.calculated_score
  end

  it "should be able to penalize if score is under the upper limit" do
    match = ProviderSelection::Match.new(:provider_account => nil, :score => 0)
    lambda { match.penalize_by(20) }.should change(match, :calculated_score).from(0)
  end

  it "should not be able to penalize if score is equal to the upper limit" do
    match = ProviderSelection::Match.new(:provider_account => nil,
                                         :score => ProviderSelection::Match::UPPER_LIMIT)
    lambda { match.penalize_by(20) }.should_not change(match, :calculated_score).from(0)
  end


  it "should be able to reward if score is above the lower limit" do
    match = ProviderSelection::Match.new(:provider_account => nil, :score => 0)
    lambda { match.reward_by(20) }.should change(match, :calculated_score).from(0)
  end

  it "should not be able to reward if score is equal to the lower limit" do
    match = ProviderSelection::Match.new(:provider_account => nil,
                                         :score => ProviderSelection::Match::LOWER_LIMIT)
    lambda { match.reward_by(20) }.should_not change(match, :calculated_score).from(0)
  end

end