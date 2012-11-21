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

module ProviderSelection

  class Base

    @strategies = []
    @view_paths = []

    class << self
      attr_reader :strategies
      attr_reader :view_paths

      def register_strategy(name, lib_path, options = {})
        # TODO: this require call should be revised in the future considering security aspects
        require lib_path
        base_klass = "provider_selection/strategies/#{name.to_s}/base".classify.constantize
        strategy_klass = "provider_selection/strategies/#{name.to_s}/strategy".classify.constantize
        @strategies << Strategy.new(name, base_klass, strategy_klass)
      end

      def find_strategy_by_name(name)
        @strategies.detect{ |strategy| strategy.name == name.to_s }
      end

      def add_view_path(view_path)
        @view_paths << view_path
      end
    end

    attr_reader :instances
    attr_reader :errors

    def initialize(instances)
      @instances = instances
      @errors = []
      @strategy_chain = self
    end

    def calculate
      pool = @instances.first.pool
      rank = Rank.new(pool)

      # Adding a priority of 100000 to the default priority group which contains
      # all the available provider accounts.
      # The user defined priority groups has a score between -100 and +100.
      default_priority_group = PriorityGroup.new(100000)
      rank.default_priority_group = default_priority_group

      find_common_provider_accounts.each do |acc_with_hwp|
        next unless acc_with_hwp.provider_account.quota.can_start?(@instances)

        # Rescale to provider account priority to the [-100, 100] interval
        score = acc_with_hwp.provider_account.priority
        if score.present? && score > Match::UPPER_LIMIT
          score = Match::UPPER_LIMIT
        elsif score.present? && score < Match::LOWER_LIMIT
          score = Match::LOWER_LIMIT
        end

        default_priority_group.matches << Match.new(:provider_account => acc_with_hwp.provider_account,
                                                    :hardware_profile => acc_with_hwp.hardware_profile,
                                                    :score => score)
      end

      rank
    end

    def match_exists?
      rank = @strategy_chain.calculate
      rank.priority_groups.each do |priority_group|
        return true if priority_group.match_exists?
      end

      false
    end

    def next_match
      rank = @strategy_chain.calculate
      rank.ordered_priority_groups.each do |priority_group|
        random_match = priority_group.get_random_match
        return random_match if random_match.present?
      end

      nil
    end

    def chain_strategy(name, options = {})
      @strategy = self.class.find_strategy_by_name(name)
      @strategy_chain = @strategy.strategy_klass.new(@strategy_chain, options) unless @strategy.nil?

      @strategy_chain
    end

    private

    ProviderWithProfile = Struct.new(:provider_account, :hardware_profile)

    class SetOfProviderWithProfile < Array
      def intersect!(set)
        provider_accounts = set.map(&:provider_account)
        self.delete_if{ |el| ! provider_accounts.include?(el.provider_account) }
      end
    end

    def find_common_provider_accounts
      instance_matches_grouped_by_instances = @instances.map do |instance|
        filter_instance_matches(instance)
      end

      profiles = SetOfProviderWithProfile.new
      instance_matches_grouped_by_instances.each_with_index do |instance_matches, index|
        if index == 0
          instance_matches.map { |im| profiles << ProviderWithProfile.new(im.provider_account, im.hardware_profile) }
        else
          profiles.intersect!(instance_matches.collect { |im| ProviderWithProfile.new(im.provider_account, im.hardware_profile) })
        end
      end

      profiles
    end

    def filter_instance_matches(instance)
      matches, e = instance.matches
      @errors += e.map {|e| "#{instance.name}: #{e}"}
      # filter matches we used in previous retries
      matches.select {|inst_match| !instance.includes_instance_match?(inst_match)}
    end

  end

end
