# David Chuck, November 2015
#
# Copyright (c) 2014-2016 Cisco and/or its affiliates.
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
require_relative 'interface'

# Add vpc-specific constants to Cisco namespace
module Cisco
  # Vpc - node utility class for VTP configuration management
  class Vpc < NodeUtil
    attr_reader :domain
    # Constructor for Vpc
    def initialize(domain_id, instantiate=true)
      @domain = domain_id
      @set_params = {}

      create if instantiate
    end

    def self.domains
      hash = {}
      my_domain = config_get('vpc', 'domain')
      hash[my_domain] = Vpc.new(my_domain, false) unless my_domain.nil?
      hash
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return {}
    end

    def self.enabled
      config_get('vpc', 'feature')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def create
      enable unless Vpc.enabled
      config_set('vpc', 'domain', state: '', domain: @domain)
    end

    def destroy
      config_set('vpc', 'feature', state: 'no')
    end

    def enable
      config_set('vpc', 'feature', state: '')
    end

    def set_args_keys_default
      keys = { domain: @domain }
      @get_args = @set_args = keys
    end

    # rubocop:disable Style/AccessorMethodName
    def set_args_keys(hash={})
      set_args_keys_default
      @set_args = @get_args.merge!(hash) unless hash.empty?
    end
    # rubocop:enable Style/AccessorMethodNamefor

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def auto_recovery
      val = config_get('vpc', 'auto_recovery')
      val.nil? ? false : val
    end

    def auto_recovery=(val)
      set_args_keys(state: val ? '' : 'no')
      config_set('vpc', 'auto_recovery', @set_args)
    end

    def default_auto_recovery
      config_get_default('vpc', 'auto_recovery')
    end

    def auto_recovery_reload_delay
      config_get('vpc', 'auto_recovery_reload_delay')
    end

    def auto_recovery_reload_delay=(val)
      set_args_keys(delay: val)
      config_set('vpc', 'auto_recovery_reload_delay', @set_args)
    end

    def default_auto_recovery_reload_delay
      config_get_default('vpc', 'auto_recovery_reload_delay')
    end

    def delay_restore
      config_get('vpc', 'delay_restore')
    end

    def delay_restore=(delay)
      set_args_keys(delay: delay)
      config_set('vpc', 'delay_restore', @set_args)
    end

    def default_delay_restore
      config_get_default('vpc', 'delay_restore')
    end

    def delay_restore_interface_vlan
      config_get('vpc', 'delay_restore_interface_vlan')
    end

    def delay_restore_interface_vlan=(delay)
      set_args_keys(delay: delay)
      config_set('vpc', 'delay_restore_interface_vlan', @set_args)
    end

    def default_delay_restore_interface_vlan
      config_get_default('vpc', 'delay_restore_interface_vlan')
    end

    def dual_active_exclude_interface_vlan_bridge_domain
      config_get('vpc', 'dual_active_exclude_interface_vlan_bridge_domain')
    end

    def dual_active_exclude_interface_vlan_bridge_domain=(val)
      set_args_keys(state: val ? '' : 'no', range: val)
      config_set('vpc', 'dual_active_exclude_interface_vlan_bridge_domain',
                 @set_args)
    end

    def default_dual_active_exclude_interface_vlan_bridge_domain
      config_get_default('vpc',
                         'dual_active_exclude_interface_vlan_bridge_domain')
    end

    def graceful_consistency_check
      val = config_get('vpc', 'graceful_consistency_check')
      val.nil? ? false : val
    end

    def graceful_consistency_check=(val)
      set_args_keys(state: val ? '' : 'no')
      config_set('vpc', 'graceful_consistency_check', @set_args)
    end

    def default_graceful_consistency_check
      config_get_default('vpc', 'graceful_consistency_check')
    end

    def layer3_peer_routing
      config_get('vpc', 'layer3_peer_routing')
    end

    def layer3_peer_routing=(val)
      set_args_keys(state: val ? '' : 'no')
      # This requires peer_gateway to be set first
      self.peer_gateway = true if !peer_gateway && val
      config_set('vpc', 'layer3_peer_routing', @set_args)
    end

    def default_layer3_peer_routing
      config_get_default('vpc', 'layer3_peer_routing')
    end

    # peer keepalive
    def peer_keepalive_dest
      config_get('vpc', 'peer_keepalive_dest')
    end

    def default_peer_keepalive_dest
      config_get_default('vpc', 'peer_keepalive_dest')
    end

    def peer_keepalive_hold_timeout
      config_get('vpc', 'peer_keepalive_hold_timeout')
    end

    def default_peer_keepalive_hold_timeout
      config_get_default('vpc', 'peer_keepalive_hold_timeout')
    end

    def peer_keepalive_interval
      config_get('vpc', 'peer_keepalive_interval')
    end

    def default_peer_keepalive_interval
      config_get_default('vpc', 'peer_keepalive_interval')
    end

    def peer_keepalive_interval_timeout
      config_get('vpc', 'peer_keepalive_timeout')
    end

    def default_peer_keepalive_interval_timeout
      config_get_default('vpc', 'peer_keepalive_timeout')
    end

    def peer_keepalive_precedence
      config_get('vpc', 'peer_keepalive_precedence')
    end

    def default_peer_keepalive_precedence
      config_get_default('vpc', 'peer_keepalive_precedence')
    end

    def peer_keepalive_src
      config_get('vpc', 'peer_keepalive_src')
    end

    def default_peer_keepalive_src
      config_get_default('vpc', 'peer_keepalive_src')
    end

    def peer_keepalive_udp_port
      config_get('vpc', 'peer_keepalive_udp_port')
    end

    def default_peer_keepalive_udp_port
      config_get_default('vpc', 'peer_keepalive_udp_port')
    end

    def peer_keepalive_vrf
      config_get('vpc', 'peer_keepalive_vrf')
    end

    def default_peer_keepalive_vrf
      config_get_default('vpc', 'peer_keepalive_vrf')
    end

    # common setter
    def peer_keepalive_set(dest, src, udp_port, vrf, interval, timeout,
                           prec, hold_timeout)
      set_args_keys(dest: dest, src: src, port_num: udp_port, vrf: vrf,
                    interval: interval, timeout: timeout,
                    precedence: prec, hold_timeout: hold_timeout)
      config_set('vpc', 'peer_keepalive_set', @set_args)
    end

    def peer_gateway
      config_get('vpc', 'peer_gateway')
    end

    def peer_gateway=(val)
      set_args_keys(state: val ? '' : 'no')
      # disable layer3 routing first
      self.layer3_peer_routing = false if !val && layer3_peer_routing
      config_set('vpc', 'peer_gateway', @set_args)
    end

    def default_peer_gateway
      config_get_default('vpc', 'peer_gateway')
    end

    def peer_gateway_exclude_bridge_domain
      config_get('vpc', 'peer_gateway_exclude_bridge_domain')
    end

    def peer_gateway_exclude_bridge_domain=(val)
      set_args_keys(state: val ? '' : 'no', range: val)
      config_set('vpc', 'peer_gateway_exclude_bridge_domain', @set_args)
    end

    def default_peer_gateway_exclude_bridge_domain
      config_get_default('vpc', 'peer_gateway_exclude_bridge_domain')
    end

    def peer_gateway_exclude_vlan
      config_get('vpc', 'peer_gateway_exclude_vlan')
    end

    def peer_gateway_exclude_vlan=(val)
      set_args_keys(state: val ? '' : 'no', range: val)
      config_set('vpc', 'peer_gateway_exclude_vlan', @set_args)
    end

    def default_peer_gateway_exclude_vlan
      config_get_default('vpc', 'peer_gateway_exclude_vlan')
    end

    def role_priority
      config_get('vpc', 'role_priority')
    end

    def role_priority=(priority)
      set_args_keys(priority: priority)
      config_set('vpc', 'role_priority', @set_args)
    end

    def default_role_priority
      config_get_default('vpc', 'role_priority')
    end

    def self_isolation
      val = config_get('vpc', 'self_isolation')
      val.nil? ? false : val
    end

    def self_isolation=(val)
      set_args_keys(state: val ? '' : 'no')
      config_set('vpc', 'self_isolation', @set_args)
    end

    def default_self_isolation
      config_get_default('vpc', 'self_isolation')
    end

    def shutdown
      config_get('vpc', 'shutdown')
    end

    def shutdown=(val)
      set_args_keys(state: val ? '' : 'no')
      config_set('vpc', 'shutdown', @set_args)
    end

    def default_shutdown
      config_get_default('vpc', 'shutdown')
    end

    def system_mac
      config_get('vpc', 'system_mac')
    end

    def system_mac=(mac_addr)
      set_args_keys(state: mac_addr.empty? ? 'no' : '', mac_addr: mac_addr)
      config_set('vpc', 'system_mac', @set_args)
    end

    def default_system_mac
      config_get_default('vpc', 'system_mac')
    end

    def system_priority
      config_get('vpc', 'system_priority')
    end

    def system_priority=(priority)
      set_args_keys(priority: priority)
      config_set('vpc', 'system_priority', @set_args)
    end

    def default_system_priority
      config_get_default('vpc', 'system_priority')
    end

    def track
      config_get('vpc', 'track')
    end

    def track=(val)
      unless val.nil?
        fail ArgumentError, 'retransmit_count must be an Integer' unless
          val.is_a?(Integer)
      end

      set_args_keys(state: (val == track) ? 'no' : '', val: val)
      config_set('vpc', 'track', @set_args)
    end

    def default_track
      config_get_default('vpc', 'track')
    end
  end # class Vpc
end # module Cisco
