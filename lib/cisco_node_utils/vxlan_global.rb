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

require File.join(File.dirname(__FILE__), 'node_util')

module Cisco
  # node_utils class for vxlan_global
  class VxlanGlobal < NodeUtil
    def feature_enable
      config_set('vxlan_global', 'feature', state: '')
    end

    def feature_disable
      config_set('vxlan_global', 'feature', state: 'no')
    end

    # Check current state of the configuration
    def self.feature_enabled
      feat = config_get('vxlan_global', 'feature')
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
      get_args = {}
      match = config_get('vxlan_global', 'dup_host_ip_addr_detection', get_args)
      if match.nil? || match.first.nil?
        default_dup_host_ip_addr_detection
      else
        match.first.collect(&:to_i)
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

    def dup_host_ip_addr_detection_set(state, host_moves, timeout)
      set_args = {}
      set_args[:state] = state
      set_args[:host_moves] = host_moves
      set_args[:timeout] = timeout

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
      get_args = {}
      match = config_get('vxlan_global', 'dup_host_mac_detection', get_args)
      if match.nil? || match.first.nil?
        default_dup_host_mac_detection
      else
        match.first.collect(&:to_i)
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
      set_args = {}
      set_args[:host_moves] = host_moves
      set_args[:timeout] = timeout

      config_set('vxlan_global', 'dup_host_mac_detection', set_args)
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
      mac_addr = config_get('vxlan_global', 'anycast_gateway_mac')
      mac_addr.nil? ? ' ' : mac_addr.first
    end

    def anycast_gateway_mac_set(state, mac_addr)
      fail TypeError unless mac_addr.is_a?(String)
      if state == 'no'
        config_set('vxlan_global', 'anycast_gateway_mac', 'no', ' ')
      else
        config_set('vxlan_global', 'anycast_gateway_mac', ' ', mac_addr)
      end
    end
  end # class
end # module
