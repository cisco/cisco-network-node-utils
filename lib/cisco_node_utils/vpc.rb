# David Chuck, November 2015
#
# Copyright (c) 2014-2015 Cisco and/or its affiliates.
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
      fail TypeError unless domain_id.is_a?(Integer)
      @domain = domain_id
      @set_params = {}

      create if instantiate
    end

    def self.domains
      hash = {}
      my_domain = config_get('vpc', 'domain')
      hash[my_domain] = Vpc.new(my_domain, false) unless my_domain.nil?
      hash
    end

    def self.enabled
      config_get('vpc', 'feature')
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

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def auto_recovery
      val = config_get('vpc', 'auto_recovery')
      val.nil? ? false : val
    end

    def auto_recovery=(val)
      config_get('vpc', 'auto_recovery', state: val ? '' : 'no')
    end

    def default_auto_recovery
      config_get_default('vpc', 'auto_recovery')
    end

    def auto_recovery_reload_delay
      config_get('vpc', 'auto_recovery_reload_delay')
    end

    def auto_recovery_reload_delay=(val)
      config_get('vpc', 'auto_recovery_reload_delay', delay: val)
    end

    def default_auto_recovery_reload_delay
      config_get_default('vpc', 'auto_recovery_reload_delay')
    end

    def delay_restore
      config_get('vpc', 'delay_restore')
    end

    def delay_restore=(delay)
      config_set('vpc', 'delay_restore', delay: delay)
    end

    def default_delay_restore
      config_get_default('vpc', 'delay_restore')
    end

    def delay_restore_interface_vlan
      config_get('vpc', 'delay_restore_interface_vlan')
    end

    def delay_restore_interface_vlan=(delay)
      config_set('vpc', 'delay_restore_interface_vlan', delay: delay)
    end

    def default_delay_restore_interface_vlan
      config_get_default('vpc', 'delay_restore_interface_vlan')
    end

    def dual_active_exclude_interface_vlan_bridge_domain
      config_get('vpc', 'dual_active_exclude_interface_vlan_bridge_domain')
    end

    def dual_active_exclude_interface_vlan_bridge_domain=(val)
      config_set('vpc', 'dual_active_exclude_interface_vlan_bridge_domain',
                 state: val ? '' : 'no', range: val)
    end

    def default_dual_active_exclude_interface_vlan_bridge_domain
      config_get_default('vpc',
                         'dual_active_exclude_interface_vlan_bridge_domain')
    end

    def layer3_peer_routing
      config_get('vpc', 'layer3_peer_routing')
    end

    def layer3_peer_routing=(val)
      config_set('vpc', 'layer3_peer_routing', state:  val ? '' : 'no')
    end

    def default_layer3_peer_routing
      config_get_default('vpc', 'layer3_peer_routing')
    end

    def peer_gateway
      config_get('vpc', 'peer_gateway')
    end

    def peer_gateway=(val)
      config_set('vpc', 'peer_gateway', state: val ? '' : 'no')
    end

    def default_peer_gateway
      config_get_default('vpc', 'peer_gateway')
    end

    def peer_gateway_exclude_vlan
      config_get('vpc', 'peer_gateway_exclude_vlan')
    end

    def peer_gateway_exclude_vlan=(val)
      config_set('vpc', 'peer_gateway_exclude_vlan', state: val ? '' : 'no',
                                                     range: val)
    end

    def default_peer_gateway_exclude_vlan
      config_get_default('vpc', 'peer_gateway_exclude_vlan')
    end
  end # class Vpc
end # module Cisco
