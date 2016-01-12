# VXLAN global provider class
# Provides configuration of anycast gateways and duplicate host IP and
# mac detection
#
# Alok Aggarwal, October 2015
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

module Cisco
  # node_utils class for vxlan_global
  class VxlanGlobal < NodeUtil
    # Constructor for vxlan_global
    def initialize(instantiate=true)
      enable if instantiate && !VxlanGlobal.enabled
    end

    def enable
      config_set('feature', 'fabric_forwarding', state: '')
    end

    def disable
      config_set('feature', 'fabric_forwarding', state: 'no')
      dup_host_mac_detection_default
    end

    # Check current state of the configuration
    def self.enabled
      feat = config_get('feature', 'fabric_forwarding')
      return !(feat.nil? || feat.empty?)
    rescue Cisco::CliError => e
      # This cmd will syntax reject if feature is not
      # enabled. Just catch the reject and return false.
      return false if e.clierror =~ /Syntax error/
      raise
    end

    # ----------
    # PROPERTIES
    # ----------

    # dup-host-ip-addr-detection
    def dup_host_ip_addr_detection
      match = config_get('vxlan_global', 'dup_host_ip_addr_detection')
      if match.nil?
        default_dup_host_ip_addr_detection
      else
        match.collect(&:to_i)
      end
    end

    def dup_host_ip_addr_detection_host_moves
      host_moves, _timeout = dup_host_ip_addr_detection
      return default_dup_host_ip_addr_detection_host_moves if host_moves.nil?
      host_moves
    end

    def dup_host_ip_addr_detection_timeout
      _host_moves, timeout = dup_host_ip_addr_detection
      return default_dup_host_ip_addr_detection_timeout if timeout.nil?
      timeout
    end

    def dup_host_ip_addr_detection_set(host_moves, timeout)
      if host_moves == default_dup_host_ip_addr_detection_host_moves &&
         timeout == default_dup_host_ip_addr_detection_timeout
        state = 'no'
      else
        state = ''
      end
      set_args = { state: state, host_moves: host_moves, timeout: timeout }
      config_set('vxlan_global', 'dup_host_ip_addr_detection', set_args)
    end

    def default_dup_host_ip_addr_detection
      [default_dup_host_ip_addr_detection_host_moves,
       default_dup_host_ip_addr_detection_timeout]
    end

    def default_dup_host_ip_addr_detection_host_moves
      config_get_default('vxlan_global',
                         'dup_host_ip_addr_detection_host_moves')
    end

    def default_dup_host_ip_addr_detection_timeout
      config_get_default('vxlan_global', 'dup_host_ip_addr_detection_timeout')
    end

    # dup-host-mac-detection
    def dup_host_mac_detection
      match = config_get('vxlan_global', 'dup_host_mac_detection')
      if match.nil?
        default_dup_host_mac_detection
      else
        match.collect(&:to_i)
      end
    end

    def dup_host_mac_detection_host_moves
      host_moves, _timeout = dup_host_mac_detection
      return default_dup_host_mac_detection_host_moves if host_moves.nil?
      host_moves
    end

    def dup_host_mac_detection_timeout
      _host_moves, timeout = dup_host_mac_detection
      return default_dup_host_mac_detection_timeout if timeout.nil?
      timeout
    end

    def dup_host_mac_detection_set(host_moves, timeout)
      set_args = { host_moves: host_moves, timeout: timeout }
      if host_moves == default_dup_host_mac_detection_host_moves &&
         timeout == default_dup_host_mac_detection_timeout
        dup_host_mac_detection_default
      else
        config_set('vxlan_global', 'dup_host_mac_detection', set_args)
      end
    end

    def dup_host_mac_detection_default
      config_set('vxlan_global', 'dup_host_mac_detection_default')
    end

    def default_dup_host_mac_detection
      [default_dup_host_mac_detection_host_moves,
       default_dup_host_mac_detection_timeout]
    end

    def default_dup_host_mac_detection_host_moves
      config_get_default('vxlan_global', 'dup_host_mac_detection_host_moves')
    end

    def default_dup_host_mac_detection_timeout
      config_get_default('vxlan_global', 'dup_host_mac_detection_timeout')
    end

    # anycast-gateway-mac
    def anycast_gateway_mac
      config_get('vxlan_global', 'anycast_gateway_mac')
    end

    def anycast_gateway_mac=(mac_addr)
      fail TypeError unless mac_addr.is_a?(String)

      if mac_addr == default_anycast_gateway_mac
        state = 'no'
        mac_addr = ''
      else
        state = ''
      end
      config_set('vxlan_global', 'anycast_gateway_mac',
                 state: state, mac_addr: mac_addr)
    end

    def default_anycast_gateway_mac
      config_get_default('vxlan_global', 'anycast_gateway_mac')
    end
  end # class
end # module
