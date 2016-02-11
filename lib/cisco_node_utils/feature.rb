# January 2016, Robert W Gries
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

module Cisco
  # Feature - node util class for managing common features
  class Feature < NodeUtil
    # Note that in most cases the enable methods should only enable;
    # however, for test purposes it is sometimes convenient to support
    # feature disablement for cleanup purposes.
    # ---------------------------
    def self.bgp_enable
      return if bgp_enabled?
      config_set('feature', 'bgp')
    end

    def self.bgp_enabled?
      config_get('feature', 'bgp')
    end

    # ---------------------------
    def self.fabric_enable
      # install feature-set and enable it
      return if fabric_enabled?
      config_set('feature', 'fabric', state: 'install') unless fabric_installed?
      config_set('feature', 'fabric', state: '')
    end

    def self.fabric_enabled?
      config_get('feature', 'fabric') =~ /^enabled/
    end

    def self.fabric_installed?
      config_get('feature', 'fabric') !~ /^uninstalled/
    end

    def self.fabric_supported?
      config_get('feature', 'fabric')
    end

    #  ---------------------------
    def self.fabric_forwarding_enable
      return if fabric_forwarding_enabled?
      Feature.fabric_enable if Feature.fabric_supported?
      # The feature fabric-forwarding cli is required in some older nxos images
      # but is not present in newer images because nv_overlay_evpn handles
      # both features; therefore feature fabric-forwarding is best-effort
      # and ignored on cli failure.
      begin
        config_set('feature', 'fabric_forwarding')
      rescue Cisco::CliError
        CiscoLogger.debug '"feature fabric forwarding" CLI was rejected'
      end
    end

    def self.fabric_forwarding_enabled?
      config_get('feature', 'fabric_forwarding')
    end

    # ---------------------------
    def self.nv_overlay_enable
      # Note: vdc platforms restrict this feature to F3 or newer linecards
      return if nv_overlay_enabled?
      config_set('feature', 'nv_overlay')
    end

    def self.nv_overlay_enabled?
      config_get('feature', 'nv_overlay')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    # ---------------------------
    def self.nv_overlay_evpn_enable
      return if nv_overlay_evpn_enabled?
      config_set('feature', 'nv_overlay_evpn')
    end

    def self.nv_overlay_evpn_enabled?
      config_get('feature', 'nv_overlay_evpn')
    end

    # ---------------------------
    def self.vn_segment_vlan_based_enable
      return if vn_segment_vlan_based_enabled?
      config_set('feature', 'vn_segment_vlan_based')
    end

    def self.vn_segment_vlan_based_enabled?
      config_get('feature', 'vn_segment_vlan_based')
    end

    # ---------------------------
  end
end
