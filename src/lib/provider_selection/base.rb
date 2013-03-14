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

    attr_reader :assembly_instances
    attr_reader :rank
    attr_reader :errors

    def initialize(pool, assembly_instances)
      @pool = pool
      @assembly_instances = assembly_instances
      @errors = []
      @strategy_chain = self

      build_strategy_chain
      build_rank
    end

    def valid?
      @errors.empty?
    end

    def calculate
      @rank
    end

    def match_exists?
      @rank.priority_groups.each do |priority_group|
        return true if priority_group.match_exists?
      end

      false
    end

    def next_match
      @rank.ordered_priority_groups.each do |priority_group|
        random_match = priority_group.get_random_match
        return random_match if random_match.present?
      end

      nil
    end

    private

    def build_strategy_chain
      @pool.provider_selection_strategies.enabled.each do  |strategy|
        chain_strategy(strategy.name, strategy.config)
      end
    end

    def build_rank
      @rank = Rank.build_from_assembly_instances(@pool, @assembly_instances)

      if @rank.default_priority_group.matches.length == 0
        @errors << I18n.t('deployments.errors.match_not_found')
      else
        @strategy_chain.calculate
      end
    end

    def chain_strategy(name, options = {})
      @strategy = self.class.find_strategy_by_name(name)
      @strategy_chain = @strategy.strategy_klass.new(@strategy_chain, options) unless @strategy.nil?
    end

  end

end
