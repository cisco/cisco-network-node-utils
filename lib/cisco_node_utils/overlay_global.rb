# VXLAN global provider class
# Provides configuration of anycast gateways and duplicate host IP and
# mac detection
#
# Alok Aggarwal, October 2015
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

require_relative 'cisco_cmn_utils'
require_relative 'feature'
require_relative 'node_util'

module Cisco
  # node_utils class for overlay_global
  class OverlayGlobal < NodeUtil
    # ----------
    # PROPERTIES
    # ----------

    # dup-host-ip-addr-detection
    def dup_host_ip_addr_detection
      return nil unless Feature.nv_overlay_evpn_enabled?
      match = config_get('overlay_global', 'dup_host_ip_addr_detection')
      if match.nil?
        default_dup_host_ip_addr_detection
      else
        match.collect(&:to_i)
      end
    end

    def dup_host_ip_addr_detection_host_moves
      host_moves, _timeout = dup_host_ip_addr_detection
      host_moves
    end

    def dup_host_ip_addr_detection_timeout
      _host_moves, timeout = dup_host_ip_addr_detection
      timeout
    end

    def dup_host_ip_addr_detection_set(host_moves, timeout)
      Feature.nv_overlay_evpn_enable
      if host_moves == default_dup_host_ip_addr_detection_host_moves &&
         timeout == default_dup_host_ip_addr_detection_timeout
        state = 'no'
      else
        state = ''
      end
      set_args = { state: state, host_moves: host_moves, timeout: timeout }
      config_set('overlay_global', 'dup_host_ip_addr_detection', set_args)
    end

    def default_dup_host_ip_addr_detection
      [default_dup_host_ip_addr_detection_host_moves,
       default_dup_host_ip_addr_detection_timeout]
    end

    def default_dup_host_ip_addr_detection_host_moves
      config_get_default('overlay_global',
                         'dup_host_ip_addr_detection_host_moves')
    end

    def default_dup_host_ip_addr_detection_timeout
      config_get_default('overlay_global', 'dup_host_ip_addr_detection_timeout')
    end

    # dup-host-mac-detection
    def dup_host_mac_detection
      match = config_get('overlay_global', 'dup_host_mac_detection')
      if match.nil?
        default_dup_host_mac_detection
      else
        match.collect(&:to_i)
      end
    end

    def dup_host_mac_detection_host_moves
      host_moves, _timeout = dup_host_mac_detection
      host_moves
    end

    def dup_host_mac_detection_timeout
      _host_moves, timeout = dup_host_mac_detection
      timeout
    end

    def dup_host_mac_detection_set(host_moves, timeout)
      set_args = { host_moves: host_moves, timeout: timeout }
      if host_moves == default_dup_host_mac_detection_host_moves &&
         timeout == default_dup_host_mac_detection_timeout
        dup_host_mac_detection_default
      else
        config_set('overlay_global', 'dup_host_mac_detection', set_args)
      end
    end

    def dup_host_mac_detection_default
      config_set('overlay_global', 'dup_host_mac_detection_default')
    end

    def default_dup_host_mac_detection
      [default_dup_host_mac_detection_host_moves,
       default_dup_host_mac_detection_timeout]
    end

    def default_dup_host_mac_detection_host_moves
      config_get_default('overlay_global', 'dup_host_mac_detection_host_moves')
    end

    def default_dup_host_mac_detection_timeout
      config_get_default('overlay_global', 'dup_host_mac_detection_timeout')
    end

    # anycast-gateway-mac
    def anycast_gateway_mac
      return nil unless Feature.nv_overlay_evpn_enabled?
      mac = config_get('overlay_global', 'anycast_gateway_mac')
      # This value gets 0-padded when nvgened, so we need to convert it.
      Utils.zero_pad_macaddr(mac).nil? ? default_anycast_gateway_mac : mac
    end

    def anycast_gateway_mac=(mac_addr)
      fail TypeError unless mac_addr.is_a?(String)

      Feature.nv_overlay_evpn_enable
      Feature.fabric_forwarding_enable
      if mac_addr == default_anycast_gateway_mac
        state = 'no'
        mac_addr = ''
      else
        state = ''
      end
      config_set('overlay_global', 'anycast_gateway_mac',
                 state: state, mac_addr: mac_addr)
    end

    def default_anycast_gateway_mac
      config_get_default('overlay_global', 'anycast_gateway_mac')
    end
  end # class
end # module
