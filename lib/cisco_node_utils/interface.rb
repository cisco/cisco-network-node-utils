# November 2015, Chris Van Heuveln
#
# Copyright (c) 2015 Cisco and/or its affiliates.
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

# Add some interface-specific constants to the Cisco namespace
module Cisco
  IF_SWITCHPORT_MODE = {
    disabled:   '',
    access:     'access',
    trunk:      'trunk',
    fex_fabric: 'fex-fabric',
    tunnel:     'dot1q-tunnel',
  }

  # Interface - node utility class for general interface config management
  class Interface < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      fail ArgumentError unless name.length > 0
      @name = name.downcase

      create if instantiate
    end

    def self.interfaces
      hash = {}
      intf_list = config_get('interface', 'all_interfaces')
      return hash if intf_list.nil?

      intf_list.each do |id|
        id = id.downcase
        hash[id] = Interface.new(id, false)
      end
      hash
    end

    def create
      feature_vlan_set(true) if @name[/vlan/i]
      config_set('interface', 'create', @name)
    end

    def destroy
      config_set('interface', 'destroy', @name)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def access_vlan
      vlan = config_get('interface', 'access_vlan', @name)
      return default_access_vlan if vlan.nil?
      vlan.shift.to_i
    end

    def access_vlan=(vlan)
      config_set('interface', 'access_vlan', @name, vlan)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_access_vlan
      config_get_default('interface', 'access_vlan')
    end

    def description
      desc = config_get('interface', 'description', @name)
      return '' if desc.nil?
      desc.shift.strip
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      if desc.empty?
        config_set('interface', 'description', @name, 'no', '')
      else
        config_set('interface', 'description', @name, '', desc)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_description
      config_get_default('interface', 'description')
    end

    def encapsulation_dot1q
      val = config_get('interface', 'encapsulation_dot1q', @name)
      return default_encapsulation_dot1q if val.nil?
      val.shift.strip.to_i
    end

    def encapsulation_dot1q=(val)
      if val.to_s.empty?
        config_set('interface', 'encapsulation_dot1q', @name, 'no', '')
      else
        config_set('interface', 'encapsulation_dot1q', @name, '', val)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_encapsulation_dot1q
      config_get_default('interface', 'encapsulation_dot1q')
    end

    def fex_feature
      fex = config_get('fex', 'feature')
      fail 'fex_feature not found' if fex.nil?
      fex.shift.to_sym
    end

    def fex_feature_set(fex_set)
      curr = fex_feature
      return if curr == fex_set

      case fex_set
      when :enabled
        config_set('fex', 'feature_install', '') if curr == :uninstalled
        config_set('fex', 'feature', '')
      when :disabled
        config_set('fex', 'feature', 'no') if curr == :enabled
        return
      when :installed
        config_set('fex', 'feature_install', '') if curr == :uninstalled
      when :uninstalled
        config_set('fex', 'feature', 'no') if curr == :enabled
        config_set('fex', 'feature_install', 'no')
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def ipv4_addr_mask
      config_get('interface', 'ipv4_addr_mask', @name)
    end

    def ipv4_addr_mask_set(addr, mask)
      check_switchport_disabled
      if addr.nil? || addr == default_ipv4_address
        config_set('interface', 'ipv4_addr_mask', @name, 'no', '')
      else
        config_set('interface', 'ipv4_addr_mask', @name, '',
                   "#{addr}/#{mask}")
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def ipv4_address
      val = ipv4_addr_mask
      return default_ipv4_address if val.nil?
      # val is [[addr, mask]] - we just want the addr
      val.shift.first
    end

    def default_ipv4_address
      config_get_default('interface', 'ipv4_address')
    end

    def ipv4_netmask_length
      val = ipv4_addr_mask
      return default_ipv4_netmask_length if val.nil?
      # val is [[addr, mask]] - we just want the mask
      val.shift.last.to_i
    end

    def default_ipv4_netmask_length
      config_get_default('interface', 'ipv4_netmask_length')
    end

    def ipv4_proxy_arp
      state = config_get('interface', 'ipv4_proxy_arp', @name)
      state.nil? ? false : true
    end

    def ipv4_proxy_arp=(proxy_arp)
      check_switchport_disabled
      no_cmd = (proxy_arp ? '' : 'no')
      config_set('interface', 'ipv4_proxy_arp', @name, no_cmd)
    end

    def default_ipv4_proxy_arp
      config_get_default('interface', 'ipv4_proxy_arp')
    end

    def ipv4_redirects_lookup_string
      case @name
      when /loopback/i
        return 'ipv4_redirects_loopback'
      else
        return 'ipv4_redirects_other_interfaces'
      end
    end

    def ipv4_redirects
      begin
        state = config_get('interface',
                           ipv4_redirects_lookup_string, @name)
      rescue IndexError
        state = nil
      end
      # We return default state for the platform if the platform doesn't support
      # the command
      return default_ipv4_redirects if state.nil? || state.empty?
      state.shift[/^ip redirects$/] ? true : false
    end

    def ipv4_redirects=(redirects)
      check_switchport_disabled
      no_cmd = (redirects ? '' : 'no')
      config_set('interface', ipv4_redirects_lookup_string, @name, no_cmd)
    rescue IndexError
      raise "ipv4 redirects not supported on #{@name}"
    end

    def default_ipv4_redirects
      config_get_default('interface', ipv4_redirects_lookup_string)
    end

    def feature_lacp?
      !config_get('interface', 'feature_lacp').nil?
    end

    def feature_lacp_set(val)
      return if feature_lacp? == val
      config_set('interface', 'feature_lacp', val ? '' : 'no')
    end

    def mtu
      mtu = config_get('interface', 'mtu', @name)
      return default_mtu if mtu.nil?
      mtu.shift.strip.to_i
    end

    def mtu=(val)
      check_switchport_disabled
      config_set('interface', 'mtu', @name, '', val)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_mtu
      config_get_default('interface', 'mtu')
    end

    def negotiate_auto_lookup_string
      case @name
      when /Ethernet/i
        return 'negotiate_auto_ethernet'
      when /port-channel/i # Ether-channel
        return 'negotiate_auto_portchannel'
      else
        return 'negotiate_auto_other_interfaces'
      end
    end

    def negotiate_auto
      lookup = negotiate_auto_lookup_string
      begin
        state = config_get('interface', lookup, @name)
      rescue IndexError
        # We return default state even if the config_get is not supported
        # for this platform / interface type. This is done so that we can set
        # the manifest to 'default' so there is a 'workaround' for the
        # unsupported attribute
        return default_negotiate_auto
      end
      state.nil? ? false : true
    end

    def negotiate_auto=(negotiate_auto)
      lookup = negotiate_auto_lookup_string
      no_cmd = (negotiate_auto ? '' : 'no')
      begin
        config_set('interface', lookup, @name, no_cmd)
      rescue Cisco::CliError => e
        raise "[#{@name}] '#{e.command}' : #{e.clierror}"
      rescue IndexError
        raise "[#{@name}] negotiate_auto is not supported on this interface"
      end
    end

    def default_negotiate_auto
      config_get_default('interface', negotiate_auto_lookup_string)
    end

    def shutdown
      state = config_get('interface', 'shutdown', @name)
      state ? true : false
    end

    def shutdown=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface', 'shutdown', @name, no_cmd)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_shutdown
      case @name
      when /Ethernet/i
        def_sw = system_default_switchport
        def_shut = system_default_switchport_shutdown

        if def_sw && def_shut
          lookup = 'shutdown_ethernet_switchport_shutdown'
        elsif def_sw && !def_shut
          lookup = 'shutdown_ethernet_switchport_noshutdown'
        elsif !def_sw && def_shut
          lookup = 'shutdown_ethernet_noswitchport_shutdown'
        elsif !def_sw && !def_shut
          lookup = 'shutdown_ethernet_noswitchport_noshutdown'
        else
          fail "Error: def_sw #{def_sw}, def_shut #{def_shut}"
        end

      when /loopback/i
        lookup = 'shutdown_loopback'

      when /port-channel/i # EtherChannel
        lookup = 'shutdown_ether_channel'

      when /Vlan/i
        lookup = 'shutdown_vlan'

      else
        lookup = 'shutdown_unknown'
      end
      config_get_default('interface', lookup)
    end

    def switchport
      # This is "switchport", not "switchport mode"
      sw = config_get('interface', 'switchport', @name)
      sw.nil? ? false : true
    end

    def switchport_enable(val=true)
      config_set('interface', 'switchport', @name, val ? '' : 'no')
    end

    # switchport_autostate_exclude is exclusive to switchport interfaces
    def switchport_autostate_exclude
      !config_get('interface',
                  'switchport_autostate_exclude', @name).nil?
    end

    def switchport_autostate_exclude=(val)
      # cannot configure autostate unless feature vlan is enabled
      fail 'switchport mode must be configured before switchport autostate' unless
        switchport
      feature_vlan_set(true)
      config_set('interface', 'switchport_autostate_exclude',
                 @name, val ? '' : 'no')
    end

    def default_switchport_autostate_exclude
      config_get_default('interface', 'switchport_autostate_exclude')
    end

    def switchport_mode_lookup_string
      case @name
      when /Ethernet/i
        return 'switchport_mode_ethernet'
      when /port-channel/i
        return 'switchport_mode_port_channel'
      else
        return 'switchport_mode_other_interfaces'
      end
    end

    def switchport_mode
      mode = config_get('interface', switchport_mode_lookup_string, @name)

      return mode.nil? ? :disabled : IF_SWITCHPORT_MODE.key(mode.shift)

    rescue IndexError
      # Assume this is an interface that doesn't support switchport.
      # Do not raise exception since the providers will prefetch this property
      # regardless of interface type.
      return :disabled
    end

    def switchport_enable_and_mode(mode_set)
      switchport_enable unless switchport

      if (:fex_fabric == mode_set)
        fex_feature_set(:enabled) unless (:enabled == fex_feature)
      end
      config_set('interface', switchport_mode_lookup_string, @name, '',
                 IF_SWITCHPORT_MODE[mode_set])

    rescue RuntimeError
      raise "[#{@name}] switchport_mode is not supported on this interface"
    end

    def switchport_mode=(mode_set)
      # no system default switchport
      # int e1/1
      #   switchport
      #   switchport mode [access|trunk|fex|...]
      fail ArgumentError unless IF_SWITCHPORT_MODE.keys.include? mode_set
      case mode_set
      when :disabled
        if switchport
          # Note: turn off switchport command, not switchport mode
          config_set('interface', 'switchport', @name, 'no')
        end

      when :default
        if :disabled == default_switchport_mode
          config_set('interface', switchport_mode_lookup_string,
                     @name, 'no', '')
        else
          switchport_enable_and_mode(mode_set)
        end

      else
        switchport_enable_and_mode(mode_set)
      end # case

    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_switchport_mode
      return :disabled unless system_default_switchport
      IF_SWITCHPORT_MODE.key(
        config_get_default('interface', switchport_mode_lookup_string))
    end

    def switchport_trunk_allowed_vlan
      val = config_get(
        'interface', 'switchport_trunk_allowed_vlan', @name)
      return default_switchport_trunk_allowed_vlan if val.nil?
      val.shift.strip
    end

    def switchport_trunk_allowed_vlan=(val)
      if val.nil?
        config_set(
          'interface', 'switchport_trunk_allowed_vlan', @name, 'no', '')
      else
        config_set(
          'interface', 'switchport_trunk_allowed_vlan', @name, '', val)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_switchport_trunk_allowed_vlan
      config_get_default('interface', 'switchport_trunk_allowed_vlan')
    end

    def switchport_trunk_native_vlan
      val = config_get(
        'interface', 'switchport_trunk_native_vlan', @name)
      return default_switchport_trunk_native_vlan if val.nil?
      val.shift.strip.to_i
    end

    def switchport_trunk_native_vlan=(val)
      if val.nil?
        config_set(
          'interface', 'switchport_trunk_native_vlan', @name, 'no', '')
      else
        config_set(
          'interface', 'switchport_trunk_native_vlan', @name, '', val)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_switchport_trunk_native_vlan
      config_get_default('interface', 'switchport_trunk_native_vlan')
    end

    def system_default_switchport
      # This command is a user-configurable system default.
      sys_def = config_get('interface', 'system_default_switchport')
      sys_def.nil? ? false : true
    end

    def system_default_switchport_shutdown
      # This command is a user-configurable system default.
      sys_def = config_get('interface',
                           'system_default_switchport_shutdown')
      sys_def.nil? ? false : true
    end

    def system_default_svi_autostate
      # This command is a user-configurable system default.
      sys_def = config_get('interface',
                           'system_default_svi_autostate')
      sys_def.nil? ? false : true
    end

    def switchport_vtp_mode_capable?
      !switchport_mode.to_s.match(/(access|trunk)/).nil?
    end

    def switchport_vtp
      return false unless switchport_vtp_mode_capable?
      vtp = config_get('interface', 'vtp', @name)
      vtp.nil? ? false : true
    end

    def switchport_vtp=(vtp_set)
      return false unless switchport_vtp_mode_capable?
      no_cmd = (vtp_set) ? '' : 'no'
      config_set('interface', 'vtp', @name, no_cmd)
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def svi_cmd_allowed?(cmd)
      fail "[#{@name}] Invalid interface type for command [#{cmd}]" unless
        @name[/vlan/i]
    end

    # svi_autostate is exclusive to svi interfaces
    def svi_autostate
      return nil unless @name[/^vlan/i]
      !config_get('interface', 'svi_autostate', @name).nil?
    end

    def svi_autostate=(val)
      check_switchport_disabled
      svi_cmd_allowed?('autostate')
      config_set('interface', 'svi_autostate', @name, val ? '' : 'no')
    end

    def default_svi_autostate
      system_default_svi_autostate
    end

    def feature_vlan?
      !config_get('interface', 'feature_vlan').nil?
    end

    def feature_vlan_set(val)
      return if feature_vlan? == val
      config_set('interface', 'feature_vlan', val ? '' : 'no')
    end

    # svi_management is exclusive to svi interfaces
    def svi_management
      return nil unless @name[/^vlan/i]
      !config_get('interface', 'svi_management', @name).nil?
    end

    def svi_management=(val)
      check_switchport_disabled
      svi_cmd_allowed?('management')
      config_set('interface', 'svi_management', @name, val ? '' : 'no')
    end

    def default_svi_management
      config_get_default('interface', 'svi_management')
    end

    def default_switchport_vtp
      config_get_default('interface', 'vtp')
    end

    def switchport_vtp_feature?
      config_get('vtp', 'feature')
    end

    def check_switchport_disabled
      fail "#{caller[0][/`.*'/][1..-2]} cannot be set unless switchport mode" \
        ' is disabled' unless switchport_mode == :disabled
    end

    def vrf
      vrf = config_get('interface', 'vrf', @name)
      return '' if vrf.nil?
      vrf.shift.strip
    end

    def vrf=(vrf)
      fail TypeError unless vrf.is_a?(String)
      if vrf.empty?
        config_set('interface', 'vrf', @name, 'no', '')
      else
        config_set('interface', 'vrf', @name, '', vrf)
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    def default_vrf
      config_get_default('interface', 'vrf')
    end
  end  # Class
end    # Module
