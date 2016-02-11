# Mike Wiebe, March 2015
#
# Copyright (c) 2015-2016 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'node_util'
require_relative 'router_ospf'

module Cisco
  # RouterOspfVrf - node utility class for per-VRF OSPF config management
  class RouterOspfVrf < NodeUtil
    attr_reader :name, :parent

    OSPF_AUTO_COST = {
      mbps: 'Mbps',
      gbps: 'Gbps',
    }

    OSPF_LOG_ADJACENCY = {
      none:   'none',
      log:    '',
      detail: 'detail',
    }

    def initialize(router, name, instantiate=true)
      fail TypeError if router.nil?
      fail TypeError if name.nil?
      fail ArgumentError unless router.length > 0
      fail ArgumentError unless name.length > 0
      @router = router
      @name = name
      @parent = {}
      if @name == 'default'
        @get_args = @set_args = { name: @router }
      else
        @get_args = @set_args = { name: @router, vrf: @name }
      end

      create if instantiate
    end

    # Create a hash of all router ospf vrf instances
    def self.vrfs
      hash_final = {}
      RouterOspf.routers.each do |instance|
        name = instance[0]
        vrf_ids = config_get('ospf', 'vrf', name: name)
        hash_tmp = {
          name => { 'default' => RouterOspfVrf.new(name, 'default', false) }
        }
        unless vrf_ids.nil?
          vrf_ids.each do |vrf|
            hash_tmp[name][vrf] = RouterOspfVrf.new(name, vrf, false)
          end
        end
        hash_final.merge!(hash_tmp)
      end
      hash_final
    end

    # Create one router ospf vrf instance
    def create
      @parent = RouterOspf.new(@router)
      config_set('ospf', 'vrf',
                 name: @router, state: '', vrf: @name) if @name != 'default'
    end

    # Destroy one router ospf vrf instance
    def destroy
      fail RuntimeError if @name == 'default'
      config_set('ospf', 'vrf', name: @router, state: 'no', vrf: @name)
    end

    # Helper method to delete @set_args hash keys
    def delete_set_args_keys(list)
      list.each { |key| @set_args.delete(key) }
    end

    def auto_cost
      match = config_get('ospf', 'auto_cost', @get_args)
      return default_auto_cost if match.nil?
      if match.last.nil?
        [match.first.to_i, OSPF_AUTO_COST[:mbps]]
      else
        [match.first.to_i, match.last]
      end
    end

    def auto_cost_set(cost, type)
      @set_args[:cost] = cost
      @set_args[:type] = OSPF_AUTO_COST[type]
      config_set('ospf', 'auto_cost', @set_args)
      delete_set_args_keys([:cost, :type])
    end

    def default_auto_cost
      config_get_default('ospf', 'auto_cost')
    end

    def default_metric
      config_get('ospf', 'default_metric', @get_args)
    end

    def default_metric=(metric)
      if metric == default_default_metric
        @set_args[:state] = 'no'
        @set_args[:metric] = ''
      else
        @set_args[:state] = ''
        @set_args[:metric] = metric
      end
      config_set('ospf', 'default_metric', @set_args)
      delete_set_args_keys([:state, :metric])
    end

    def default_default_metric
      config_get_default('ospf', 'default_metric')
    end

    def log_adjacency
      match = config_get('ospf', 'log_adjacency', @get_args)
      return default_log_adjacency if match.nil?
      match.flatten.last.nil? ? :log : :detail
    end

    def log_adjacency=(type)
      case type
      when :none
        @set_args[:state] = 'no'
        @set_args[:type] = ''
      when :log, :detail
        @set_args[:state] = ''
        @set_args[:type] = OSPF_LOG_ADJACENCY[type]
      end
      config_set('ospf', 'log_adjacency', @set_args)
      delete_set_args_keys([:state, :type])
    end

    def default_log_adjacency
      config_get_default('ospf', 'log_adjacency')
    end

    def router_id
      config_get('ospf', 'router_id', @get_args)
    end

    def router_id=(router_id)
      if router_id == default_router_id
        @set_args[:state] = 'no'
        @set_args[:router_id] = ''
      else
        @set_args[:state] = ''
        @set_args[:router_id] = router_id
      end

      config_set('ospf', 'router_id', @set_args)
      delete_set_args_keys([:state, :router_id])
    end

    def default_router_id
      config_get_default('ospf', 'router_id')
    end

    def timer_throttle_lsa
      match = config_get('ospf', 'timer_throttle_lsa', @get_args)
      if match.nil?
        default_timer_throttle_lsa
      else
        match.collect(&:to_i)
      end
    end

    def timer_throttle_lsa_start
      start, _hold, _max = timer_throttle_lsa
      return default_timer_throttle_lsa_start if start.nil?
      start
    end

    def timer_throttle_lsa_hold
      _start, hold, _max = timer_throttle_lsa
      return default_timer_throttle_lsa_hold if hold.nil?
      hold
    end

    def timer_throttle_lsa_max
      _start, _hold, max = timer_throttle_lsa
      return default_timer_throttle_lsa_max if max.nil?
      max
    end

    def timer_throttle_lsa_set(start, hold, max)
      @set_args[:start] = start
      @set_args[:hold] = hold
      @set_args[:max] = max
      config_set('ospf', 'timer_throttle_lsa', @set_args)
      delete_set_args_keys([:start, :hold, :max])
    end

    def default_timer_throttle_lsa
      [default_timer_throttle_lsa_start,
       default_timer_throttle_lsa_hold,
       default_timer_throttle_lsa_max]
    end

    def default_timer_throttle_lsa_start
      config_get_default('ospf', 'timer_throttle_lsa_start')
    end

    def default_timer_throttle_lsa_hold
      config_get_default('ospf', 'timer_throttle_lsa_hold')
    end

    def default_timer_throttle_lsa_max
      config_get_default('ospf', 'timer_throttle_lsa_max')
    end

    def timer_throttle_spf
      match = config_get('ospf', 'timer_throttle_spf', @get_args)
      if match.nil?
        default_timer_throttle_spf
      else
        match.collect(&:to_i)
      end
    end

    def timer_throttle_spf_start
      start, _hold, _max = timer_throttle_spf
      return default_timer_throttle_spf_start if start.nil?
      start
    end

    def timer_throttle_spf_hold
      _start, hold, _max = timer_throttle_spf
      return default_timer_throttle_spf_hold if hold.nil?
      hold
    end

    def timer_throttle_spf_max
      _start, _hold, max = timer_throttle_spf
      return default_timer_throttle_spf_max if max.nil?
      max
    end

    def timer_throttle_spf_set(start, hold, max)
      @set_args[:start] = start
      @set_args[:hold] = hold
      @set_args[:max] = max
      config_set('ospf', 'timer_throttle_spf', @set_args)
      delete_set_args_keys([:start, :hold, :max])
    end

    def default_timer_throttle_spf
      [default_timer_throttle_spf_start,
       default_timer_throttle_spf_hold,
       default_timer_throttle_spf_max]
    end

    def default_timer_throttle_spf_start
      config_get_default('ospf', 'timer_throttle_spf_start')
    end

    def default_timer_throttle_spf_hold
      config_get_default('ospf', 'timer_throttle_spf_hold')
    end

    def default_timer_throttle_spf_max
      config_get_default('ospf', 'timer_throttle_spf_max')
    end
  end
end
