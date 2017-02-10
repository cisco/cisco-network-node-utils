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
    def self.bfd_enable
      return if bfd_enabled?
      config_set('feature', 'bfd')
    end

    def self.bfd_enabled?
      config_get('feature', 'bfd')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    # ---------------------------
    def self.bgp_enable
      return if bgp_enabled?
      config_set('feature', 'bgp')
    end

    def self.bgp_enabled?
      config_get('feature', 'bgp')
    end

    # ---------------------------
    def self.dhcp_enable
      return if dhcp_enabled?
      config_set('feature', 'dhcp')
    end

    def self.dhcp_enabled?
      config_get('feature', 'dhcp')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
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
        Cisco::Logger.debug '"feature fabric forwarding" CLI was rejected'
      end
    end

    def self.fabric_forwarding_enabled?
      config_get('feature', 'fabric_forwarding')
    end

    # ---------------------------
    def self.fex_enable
      # install feature-set and enable it
      return if fex_enabled?
      config_set('feature', 'fex', state: 'install') unless fex_installed?
      config_set('feature', 'fex', state: '')
    end

    def self.fex_enabled?
      config_get('feature', 'fex') =~ /^enabled/
    end

    def self.fex_installed?
      config_get('feature', 'fex') !~ /^uninstalled/
    end

    def self.fex_supported?
      config_get('feature', 'fex')
    end

    # ---------------------------
    def self.hsrp_enable
      return if hsrp_enabled?
      config_set('feature', 'hsrp')
    end

    def self.hsrp_enabled?
      config_get('feature', 'hsrp')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    # ---------------------------
    def self.itd_enable
      return if itd_enabled?
      config_set('feature', 'itd')
    end

    def self.itd_enabled?
      config_get('feature', 'itd')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    # ---------------------------
    def self.nv_overlay_enable
      # Note: vdc platforms restrict this feature to F3 or newer linecards
      return if nv_overlay_enabled?
      config_set('feature', 'nv_overlay', state: '')
      sleep 1
    end

    def self.nv_overlay_disable
      # Note: vdc platforms restrict this feature to F3 or newer linecards
      # Note: this is for test purposes only
      return unless nv_overlay_enabled?
      config_set('feature', 'nv_overlay', state: 'no')
      sleep 1
    end

    def self.nv_overlay_enabled?
      config_get('feature', 'nv_overlay')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    def self.nv_overlay_supported?
      node.cmd_ref.supports?('feature', 'nv_overlay')
    end

    # ---------------------------
    def self.nv_overlay_evpn_enable
      return if nv_overlay_evpn_enabled?
      config_set('feature', 'nv_overlay_evpn')
    end

    def self.nv_overlay_evpn_enabled?
      config_get('feature', 'nv_overlay_evpn')
    end

    def self.nv_overlay_evpn_supported?
      node.cmd_ref.supports?('feature', 'nv_overlay_evpn')
    end

    # ---------------------------
    def self.ospf_enable
      return if ospf_enabled?
      config_set('feature', 'ospf')
    end

    def self.ospf_enabled?
      config_get('feature', 'ospf')
    end

    # ---------------------------
    def self.pim_enable
      return if pim_enabled?
      config_set('feature', 'pim')
    end

    def self.pim_enabled?
      config_get('feature', 'pim')
    end

    # ---------------------------
    def self.private_vlan_enable
      return if private_vlan_enabled?
      config_set('feature', 'private_vlan')
    end

    def self.private_vlan_enabled?
      config_get('feature', 'private_vlan')
    end

    # ---------------------------
    def self.tacacs_enable
      return if tacacs_enabled? || platform == :ios_xr
      config_set('feature', 'tacacs')
    end

    def self.tacacs_enabled?
      config_get('feature', 'tacacs')
    end

    # ---------------------------
    def self.vn_segment_vlan_based_enable
      return if vn_segment_vlan_based_enabled?
      result = config_set('feature', 'vn_segment_vlan_based')
      cli_error_check(result)
    end

    def self.vn_segment_vlan_based_enabled?
      config_get('feature', 'vn_segment_vlan_based')
    end

    # ---------------------------
    def self.vni_enable
      return if vni_enabled?
      result = config_set('feature', 'vni')
      cli_error_check(result)
    end

    def self.vni_enabled?
      config_get('feature', 'vni')
    end

    # ---------------------------
    def self.vtp_enable
      return if vtp_enabled?
      result = config_set('feature', 'vtp', state: '')
      cli_error_check(result)
    end

    # Special Case: The only way to remove a vtp instance
    # is by disabling the feature.
    def self.vtp_disable
      return unless vtp_enabled?
      config_set('feature', 'vtp', state: 'no')
    end

    def self.vtp_enabled?
      config_get('feature', 'vtp')
    rescue Cisco::CliError => e
      # cmd will syntax reject when feature is not enabled.
      raise unless e.clierror =~ /Syntax error/
      return false
    end

    # ---------------------------
    def self.cli_error_check(result)
      # The NXOS feature cli may not raise an exception in some conditions and
      # instead just displays a STDOUT error message; thus NXAPI does not detect
      # the failure and we must catch it by inspecting the "body" hash entry
      # returned by NXAPI. This cli behavior is unlikely to change soon.
      fail result[2]['body'] if
        result[2].is_a?(Hash) &&
        /Hardware is not capable of supporting/.match(result[2]['body'].to_s)

      # Some test environments get result as a string instead of a hash
      fail result if
        result.is_a?(String) &&
        /Hardware is not capable of supporting/.match(result)
    end

    # ---------------------------
    def self.compatible_interfaces(feature, property='supported_module_pids')
      # Figure out the interfaces in a modular switch that are
      # compatible with the given feature (or property within a feature)
      # and return an array of such interfaces
      module_pids = config_get(feature, property)
      return [] if module_pids.nil?
      module_regex = Regexp.new module_pids
      # first get the compatible modules present in the switch
      slots = Platform.slots.select do |_slot, filt_mod|
        filt_mod['pid'] =~ module_regex
      end
      return [] if slots.empty?
      # get the slot numbers only into filtered slots array
      filt_slots = slots.keys.map { |key| key[/\d+/] }
      # now filter interfaces in the vdc based on compatible slots
      vdc = Vdc.new(Vdc.default_vdc_name)
      filt_intfs = vdc.interface_membership.select do |intf|
        filt_slots.include? intf[/\d+/]
      end
      filt_intfs
    end
  end
end
