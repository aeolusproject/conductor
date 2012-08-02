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

class ProviderPriorityGroup < ActiveRecord::Base

  belongs_to :pool
  has_many :provider_priority_group_elements, :dependent => :destroy
  has_many :providers, :through => :provider_priority_group_elements, :source => :value, :source_type => 'Provider'
  has_many :provider_accounts, :through => :provider_priority_group_elements, :source => :value, :source_type => 'ProviderAccount'

  validates_numericality_of :score, :only_integer => true, :greater_than_or_equal_to => -100, :less_than_or_equal_to => 100

  def include?(element)
    if element.is_a?(Provider)
      providers.include?(element)
    elsif element.is_a?(ProviderAccount)
      providers.include?(element.provider) || provider_accounts.include?(element)
    end
  end

  def add_provider_accounts(selected_provider_accounts)
    selected_provider_accounts.each do |provider_account|
      unless providers.include?(provider_account.provider)
        provider_accounts << provider_account
      end
    end
  end

  def all_provider_accounts
    result = providers.inject([]) do |result, provider|
      result += provider.provider_accounts
    end

    result += provider_accounts
  end

end