# November 2015, Chris Van Heuveln
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

require_relative 'cisco_cmn_utils'
require_relative 'node_util'
require_relative 'pim'
require_relative 'vrf'
require_relative 'vni'
require_relative 'overlay_global'

# Add some interface-specific constants to the Cisco namespace
module Cisco
  IF_SWITCHPORT_MODE = {
    disabled:   '',
    access:     'access',
    trunk:      'trunk',
    fex_fabric: 'fex-fabric',
    tunnel:     'dot1q-tunnel',
    fabricpath: 'fabricpath',
  }

  # Interface - node utility class for general interface config management
  class Interface < NodeUtil
    # Regexp to match various Ethernet interface variants:
    #                       Ethernet
    #                GigabitEthernet
    #                             TenGigE
    #                         HundredGigE
    #                                     MgmtEth
    ETHERNET = Regexp.new('(Ethernet|GigE|MgmtEth)', Regexp::IGNORECASE)
    # Regexp to match various link bundle interface variants
    PORTCHANNEL = Regexp.new('(port-channel|Bundle-Ether)', Regexp::IGNORECASE)

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
      config_set('interface', 'create', name: @name)
    rescue Cisco::CliError
      # Some XR platforms do not support channel-group configuration
      # on some OS versions. Since this is an OS version difference and not
      # a platform difference, we can't handle this in the YAML.
      raise unless PORTCHANNEL =~ @name && platform == :ios_xr
      raise Cisco::UnsupportedError.new('interface', @name, 'create')
    end

    def destroy
      config_set('interface', 'destroy', name: @name)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def access_vlan
      config_get('interface', 'access_vlan', name: @name)
    end

    def access_vlan=(vlan)
      config_set('interface', 'access_vlan', name: @name, vlan: vlan)
    end

    def default_access_vlan
      config_get_default('interface', 'access_vlan')
    end

    def description
      config_get('interface', 'description', name: @name)
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      if desc.strip.empty?
        config_set('interface', 'description',
                   name: @name, state: 'no', desc: '')
      else
        config_set('interface', 'description',
                   name: @name, state: '', desc: desc)
      end
    end

    def default_description
      config_get_default('interface', 'description')
    end

    def encapsulation_dot1q
      config_get('interface', 'encapsulation_dot1q', name: @name)
    end

    def encapsulation_dot1q=(val)
      if val.to_s.empty?
        config_set('interface', 'encapsulation_dot1q',
                   name: @name, state: 'no', vlan: '')
      else
        config_set('interface', 'encapsulation_dot1q',
                   name: @name, state: '', vlan: val)
      end
    end

    def default_encapsulation_dot1q
      config_get_default('interface', 'encapsulation_dot1q')
    end

    def fabricpath_feature
      FabricpathGlobal.fabricpath_feature
    end

    def fabricpath_feature_set(fabricpath_set)
      FabricpathGlobal.fabricpath_feature_set(fabricpath_set)
    end

    def fabric_forwarding_anycast_gateway
      config_get('interface', 'fabric_forwarding_anycast_gateway', name: @name)
    end

    def fabric_forwarding_anycast_gateway=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface',
                 'fabric_forwarding_anycast_gateway',
                 name: @name, state: no_cmd)
      fail if fabric_forwarding_anycast_gateway.to_s != state.to_s
    rescue Cisco::CliError => e
      info = "[#{@name}] '#{e.command}' : #{e.clierror}"
      raise "#{info} 'fabric_forwarding_anycast_gateway' can only be " \
        'configured on a vlan interface' unless /vlan/.match(@name)
      anycast_gateway_mac = OverlayGlobal.new.anycast_gateway_mac
      if anycast_gateway_mac.nil? || anycast_gateway_mac.empty?
        raise "#{info} Anycast gateway mac must be configured " \
               'before configuring forwarding mode under interface'
      end
      raise info
    end

    def default_fabric_forwarding_anycast_gateway
      config_get_default('interface', 'fabric_forwarding_anycast_gateway')
    end

    def fex_feature
      fex = config_get('fex', 'feature')
      fail 'fex_feature not found' if fex.nil?
      fex.to_sym
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
    end

    def ipv4_acl_in
      config_get('interface', 'ipv4_acl_in', name: @name)
    end

    def ipv4_acl_in=(val)
      if val != ''
        state = ''
      else
        state = 'no'
        val = ipv4_acl_in
      end

      return unless val && val != ''
      config_set('interface', 'ipv4_acl_in',
                 name: @name, state: state, acl: val)
    end

    def default_ipv4_acl_in
      config_get_default('interface', 'ipv4_acl_in')
    end

    def ipv4_acl_out
      config_get('interface', 'ipv4_acl_out', name: @name)
    end

    def ipv4_acl_out=(val)
      if val != ''
        state = ''
      else
        state = 'no'
        val = ipv4_acl_out
      end

      return unless val && val != ''
      config_set('interface', 'ipv4_acl_out',
                 name: @name, state: state, acl: val)
    end

    def default_ipv4_acl_out
      config_get_default('interface', 'ipv4_acl_out')
    end

    def ipv4_addr_mask_set(addr, mask, secondary=false)
      check_switchport_disabled
      sec = secondary ? 'secondary' : ''
      if addr.nil? || addr == default_ipv4_address
        state = 'no'
        if secondary
          return if ipv4_address_secondary == default_ipv4_address_secondary
          # We need address and mask to remove.
          am = "#{ipv4_address_secondary}/#{ipv4_netmask_length_secondary}"
        else
          return if ipv4_address == default_ipv4_address
          am = "#{ipv4_address}/#{ipv4_netmask_length}"
        end
      else
        state = ''
        am = "#{addr}/#{mask}"
      end
      config_set('interface', 'ipv4_addr_mask',
                 name: @name, state: state, addr: am, secondary: sec)
    end

    def ipv4_addr_mask
      val = config_get('interface', 'ipv4_addr_mask', name: @name)
      if val && platform == :ios_xr
        # IOS XR reports address as <address> <bitmask> [secondary] but we
        # want <address>/<length> [secondary]
        val.each_with_index do |entry, i|
          mask = entry[1].split(' ')
          mask[0] = Utils.bitmask_to_length(mask[0])
          val[i][1] = mask.join(' ')
        end
      end
      val
    end

    def select_ipv4_attribute(attribute)
      d = ipv4_addr_mask.flatten unless ipv4_addr_mask.nil?
      # (d)ata format after flatten: ['addr', 'mask', 'addr', 'mask secondary']
      case attribute
      when :v4_addr
        v = d.nil? ? default_ipv4_address : d[0]
      when :v4_mask
        v = d.nil? ? default_ipv4_netmask_length : d[1].to_i
      when :v4_addr_secondary
        v = (d.nil? || d.size < 4) ? default_ipv4_address : d[2]
      when :v4_mask_secondary
        if d.nil? || d.size < 4
          v = default_ipv4_netmask_length
        else
          v = d[3][0, 2].to_i
        end
      end
      v
    end

    def ipv4_address
      select_ipv4_attribute(:v4_addr)
    end

    def ipv4_address_secondary
      select_ipv4_attribute(:v4_addr_secondary)
    end

    def ipv4_netmask_length
      select_ipv4_attribute(:v4_mask)
    end

    def ipv4_netmask_length_secondary
      select_ipv4_attribute(:v4_mask_secondary)
    end

    def default_ipv4_address
      config_get_default('interface', 'ipv4_address')
    end

    def default_ipv4_address_secondary
      default_ipv4_address
    end

    def default_ipv4_netmask_length
      config_get_default('interface', 'ipv4_netmask_length')
    end

    def default_ipv4_netmask_length_secondary
      default_ipv4_netmask_length
    end

    def ipv4_arp_timeout_lookup_string
      case @name
      when /vlan/i
        return 'ipv4_arp_timeout'
      else
        return 'ipv4_arp_timeout_non_vlan_interfaces'
      end
    end

    def ipv4_arp_timeout
      config_get('interface', ipv4_arp_timeout_lookup_string, name: @name)
    end

    def ipv4_arp_timeout=(timeout)
      fail "'ipv4 arp timeout' can ony be configured on a vlan interface" unless
        /vlan/.match(@name)
      state = (timeout == default_ipv4_arp_timeout) ? 'no' : ''
      config_set('interface', 'ipv4_arp_timeout',
                 name: @name, state: state, timeout: timeout)
    end

    def default_ipv4_arp_timeout
      config_get_default('interface', ipv4_arp_timeout_lookup_string)
    end

    def ipv4_forwarding
      config_get('interface', 'ipv4_forwarding', name: @name)
    end

    def ipv4_forwarding=(state)
      config_set('interface', 'ipv4_forwarding', name: @name,
                 state: state ? '' : 'no')
    end

    def default_ipv4_forwarding
      config_get_default('interface', 'ipv4_forwarding')
    end

    def ipv4_pim_sparse_mode
      config_get('interface', 'ipv4_pim_sparse_mode', name: @name)
    end

    def ipv4_pim_sparse_mode=(state)
      check_switchport_disabled
      Pim.feature_enable unless platform == :ios_xr || Pim.feature_enabled
      config_set('interface', 'ipv4_pim_sparse_mode',
                 name: @name, state: state ? '' : 'no')
    end

    def default_ipv4_pim_sparse_mode
      config_get_default('interface', 'ipv4_pim_sparse_mode')
    end

    def ipv4_proxy_arp
      config_get('interface', 'ipv4_proxy_arp', name: @name)
    end

    def ipv4_proxy_arp=(proxy_arp)
      check_switchport_disabled
      no_cmd = (proxy_arp ? '' : 'no')
      config_set('interface', 'ipv4_proxy_arp', name: @name, state: no_cmd)
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
      config_get('interface', ipv4_redirects_lookup_string, name: @name)
    end

    def ipv4_redirects=(redirects)
      check_switchport_disabled
      no_cmd = (redirects ? '' : 'no')
      config_set('interface', ipv4_redirects_lookup_string,
                 name: @name, state: no_cmd)
    end

    def default_ipv4_redirects
      config_get_default('interface', ipv4_redirects_lookup_string)
    end

    def ipv6_acl_in
      config_get('interface', 'ipv6_acl_in', name: @name)
    end

    def ipv6_acl_in=(val)
      if val != ''
        state = ''
      else
        state = 'no'
        val = ipv6_acl_in
      end
      return unless val && val != ''
      config_set('interface', 'ipv6_acl_in',
                 name: @name, state: state, acl: val)
    end

    def default_ipv6_acl_in
      config_get_default('interface', 'ipv6_acl_in')
    end

    def ipv6_acl_out
      config_get('interface', 'ipv6_acl_out', name: @name)
    end

    def ipv6_acl_out=(val)
      if val != ''
        state = ''
      else
        state = 'no'
        val = ipv6_acl_out
      end
      return unless val && val != ''
      config_set('interface', 'ipv6_acl_out',
                 name: @name, state: state, acl: val)
    end

    def default_ipv6_acl_out
      config_get_default('interface', 'ipv6_acl_out')
    end

    def feature_lacp?
      config_get('interface', 'feature_lacp')
    end

    def feature_lacp_set(val)
      return if feature_lacp? == val
      config_set('interface', 'feature_lacp', state: val ? '' : 'no')
    end

    def mtu_lookup_string
      case @name
      when /loopback/i
        return 'mtu_loopback'
      else
        return 'mtu_other_interfaces'
      end
    end

    def mtu
      config_get('interface', mtu_lookup_string, name: @name)
    end

    def mtu=(val)
      check_switchport_disabled
      config_set('interface', mtu_lookup_string,
                 name: @name, state: '', mtu: val)
    end

    def default_mtu
      config_get_default('interface', mtu_lookup_string)
    end

    def speed
      config_get('interface', 'speed', name: @name)
    end

    def speed=(val)
      if node.product_id =~ /C31\d\d/
        fail 'Changing interface speed is not permitted on this platform'
      end
      config_set('interface', 'speed', name: @name, speed: val)
    end

    def default_speed
      config_get_default('interface', 'speed')
    end

    def duplex
      config_get('interface', 'duplex', name: @name)
    end

    def duplex=(val)
      if node.product_id =~ /C31\d\d/
        fail 'Changing interface duplex is not permitted on this platform'
      end
      config_set('interface', 'duplex', name: @name, duplex: val)
    end

    def default_duplex
      config_get_default('interface', 'duplex')
    end

    def negotiate_auto_lookup_string
      case @name
      when ETHERNET
        return 'negotiate_auto_ethernet'
      when PORTCHANNEL
        return 'negotiate_auto_portchannel'
      else
        return 'negotiate_auto_other_interfaces'
      end
    end

    def negotiate_auto
      config_get('interface', negotiate_auto_lookup_string, name: @name)
    end

    def negotiate_auto=(negotiate_auto)
      lookup = negotiate_auto_lookup_string
      no_cmd = (negotiate_auto ? '' : 'no')
      config_set('interface', lookup, name: @name, state: no_cmd)
    end

    def default_negotiate_auto
      config_get_default('interface', negotiate_auto_lookup_string)
    end

    def shutdown
      config_get('interface', 'shutdown', name: @name)
    end

    def shutdown=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface', 'shutdown', name: @name, state: no_cmd)
    end

    def default_shutdown
      case @name
      when ETHERNET
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

      when PORTCHANNEL
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
      config_get('interface', 'switchport', name: @name)
    end

    def switchport_enable(val=true)
      config_set('interface', 'switchport', name: @name, state: val ? '' : 'no')
    end

    # switchport_autostate_exclude is exclusive to switchport interfaces
    def switchport_autostate_exclude
      config_get('interface',
                 'switchport_autostate_exclude', name: @name)
    end

    def switchport_autostate_exclude=(val)
      if platform == :nexus
        # cannot configure autostate unless feature vlan is enabled
        fail('switchport mode must be configured before ' \
             'switchport autostate') unless switchport
        feature_vlan_set(true)
      end
      config_set('interface', 'switchport_autostate_exclude',
                 name: @name, state: val ? '' : 'no')
    end

    def default_switchport_autostate_exclude
      config_get_default('interface', 'switchport_autostate_exclude')
    end

    def switchport_mode_lookup_string
      case @name
      when ETHERNET
        return 'switchport_mode_ethernet'
      when PORTCHANNEL
        return 'switchport_mode_port_channel'
      else
        return 'switchport_mode_other_interfaces'
      end
    end

    def switchport_mode
      return nil if platform == :ios_xr
      mode = config_get('interface', switchport_mode_lookup_string, name: @name)

      return mode.nil? ? :disabled : IF_SWITCHPORT_MODE.key(mode)

    rescue IndexError
      # Assume this is an interface that doesn't support switchport.
      # Do not raise exception since the providers will prefetch this property
      # regardless of interface type.
      # TODO: this should probably be nil instead
      return :disabled
    end

    def switchport_enable_and_mode(mode_set)
      switchport_enable unless switchport

      if :fabricpath == mode_set
        fabricpath_feature_set(:enabled) unless :enabled == fabricpath_feature
      elsif :fex_fabric == mode_set
        fex_feature_set(:enabled) unless :enabled == fex_feature
      end
      config_set('interface', switchport_mode_lookup_string,
                 name: @name, state: '', mode: IF_SWITCHPORT_MODE[mode_set])
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
          config_set('interface', 'switchport', name: @name, state: 'no')
        end

      when :default
        if :disabled == default_switchport_mode
          config_set('interface', switchport_mode_lookup_string,
                     name: @name, state: 'no', mode: '')
        else
          switchport_enable_and_mode(mode_set)
        end

      else
        switchport_enable_and_mode(mode_set)
      end # case
    end

    def default_switchport_mode
      return nil if platform == :ios_xr
      return :disabled unless system_default_switchport
      IF_SWITCHPORT_MODE.key(
        config_get_default('interface', switchport_mode_lookup_string))
    end

    def switchport_trunk_allowed_vlan
      config_get('interface', 'switchport_trunk_allowed_vlan', name: @name)
    end

    def switchport_trunk_allowed_vlan=(val)
      if val.nil?
        config_set('interface', 'switchport_trunk_allowed_vlan',
                   name: @name, state: 'no', vlan: '')
      else
        config_set('interface', 'switchport_trunk_allowed_vlan',
                   name: @name, state: '', vlan: val)
      end
    end

    def default_switchport_trunk_allowed_vlan
      config_get_default('interface', 'switchport_trunk_allowed_vlan')
    end

    def switchport_trunk_native_vlan
      config_get('interface', 'switchport_trunk_native_vlan', name: @name)
    end

    def switchport_trunk_native_vlan=(val)
      if val.nil?
        config_set('interface', 'switchport_trunk_native_vlan',
                   name: @name, state: 'no', vlan: '')
      else
        config_set('interface', 'switchport_trunk_native_vlan',
                   name: @name, state: '', vlan: val)
      end
    end

    # vlan_mapping & vlan_mapping_enable
    #  Hardware & Cli Dependencies:
    #   - F3 linecards only
    #   - vdc
    #   - limit-resource
    #   - bridge-domain
    #   - feature vni
    #   - switchport mode

    # Getter: Builds an array of vlan_mapping commands currently
    # on the device.
    #   cli: switchport vlan mapping 2 200
    #        switchport vlan mapping 4 400
    # array: [['2', '200'], ['4', '400']]
    #
    def default_vlan_mapping
      config_get_default('interface', 'vlan_mapping')
    end

    def vlan_mapping
      match = config_get('interface', 'vlan_mapping', name: @name)
      match.each(&:compact!) unless match.nil?
      match
    end

    def vlan_mapping=(should_list)
      Feature.vni_enable

      # Process a hash of vlan_mapping cmds from delta_add_remove().
      # The vlan_mapping cli does not allow commands to be updated, they must
      # first be removed if there is a change.
      delta_hash = Utils.delta_add_remove(should_list, vlan_mapping,
                                          :updates_not_allowed)
      return if delta_hash.values.flatten.empty?
      # Process :remove first to ensure "update" commands will not fail.
      [:remove, :add].each do |action|
        Cisco::Logger.debug("vlan_mapping delta #{@get_args}\n"\
                            "#{action}: #{delta_hash[action]}")
        delta_hash[action].each do |original, translated|
          state = (action == :add) ? '' : 'no'
          config_set('interface', 'vlan_mapping', name: @name,
                     state: state, original: original, translated: translated)
        end
      end
    rescue Cisco::CliError => e
      raise "[#{@name}] '#{e.command}' : #{e.clierror}"
    end

    # cli: switchport vlan mapping enable
    def default_vlan_mapping_enable
      config_get_default('interface', 'vlan_mapping_enable')
    end

    def vlan_mapping_enable
      config_get('interface', 'vlan_mapping_enable', name: @name)
    end

    def vlan_mapping_enable=(state)
      config_set('interface', 'vlan_mapping_enable',
                 name: @name, state: state ? '' : 'no')
    end

    def default_switchport_trunk_native_vlan
      config_get_default('interface', 'switchport_trunk_native_vlan')
    end

    def system_default_switchport
      # This command is a user-configurable system default.
      #
      # Note: This is a simple boolean state but there is a bug on some
      # platforms that causes the cli to nvgen twice; this causes config_get to
      # raise an error when it encounters the multiple. Therefore we define it
      # as a multiple to avoid the raise and handle the array if necessary.
      #
      val = config_get('interface', 'system_default_switchport')
      return (val[0][/^no /] ? false : true) if val.is_a?(Array)
      val
    end

    def system_default_switchport_shutdown
      # This command is a user-configurable system default.
      config_get('interface', 'system_default_switchport_shutdown')
    end

    def system_default_svi_autostate
      # This command is a user-configurable system default.
      #
      # This property behaves differently on an n7k vs ni(3|9)k and therefore
      # needs special handling.
      # N7K: When enabled, does not nvgen.
      #      When disabled, does nvgen, but differently then n(3|9)k.
      #      Return true for the disabled case, false otherwise.
      # N(3|9)K: When enabled, does nvgen.
      #          When disabled, does nvgen.
      #          Return true for the enabled case, false otherwise.
      result = config_get('interface', 'system_default_svi_autostate')
      /N7K/.match(node.product_id) ? !result : result
    end

    def switchport_vtp_mode_capable?
      !switchport_mode.to_s.match(/(access|trunk)/).nil?
    end

    def switchport_vtp
      return nil unless switchport_vtp_mode_capable?
      config_get('interface', 'vtp', name: @name)
    end

    def switchport_vtp=(vtp_set)
      return false unless switchport_vtp_mode_capable?
      no_cmd = (vtp_set) ? '' : 'no'
      config_set('interface', 'vtp', name: @name, state: no_cmd)
    end

    def svi_cmd_allowed?(cmd)
      fail "[#{@name}] Invalid interface type for command [#{cmd}]" unless
        @name[/vlan/i]
    end

    # svi_autostate is exclusive to svi interfaces
    def svi_autostate
      return nil unless @name[/^vlan/i]
      config_get('interface', 'svi_autostate', name: @name)
    end

    def svi_autostate=(val)
      check_switchport_disabled
      svi_cmd_allowed?('autostate')
      config_set('interface', 'svi_autostate',
                 name: @name, state: val ? '' : 'no')
    end

    def default_svi_autostate
      system_default_svi_autostate
    end

    def feature_vlan?
      config_get('interface', 'feature_vlan')
    end

    def feature_vlan_set(val)
      return if feature_vlan? == val
      config_set('interface', 'feature_vlan', state: val ? '' : 'no')
    end

    # svi_management is exclusive to svi interfaces
    def svi_management
      return nil unless @name[/^vlan/i]
      config_get('interface', 'svi_management', name: @name)
    end

    def svi_management=(val)
      check_switchport_disabled
      svi_cmd_allowed?('management')
      config_set('interface', 'svi_management',
                 name: @name, state: val ? '' : 'no')
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
      return if switchport_mode == :disabled || switchport_mode.nil?
      fail("#{caller[0][/`.*'/][1..-2]} cannot be set unless " \
           'switchport mode is disabled')
    end

    def vpc_id
      config_get('interface', 'vpc_id', name: @name)
    end

    def vpc_id=(num)
      if num
        config_set('interface', 'vpc_id', name: @name, state: '', id: num)
      else
        # 'no vpc' doesn't work for phy ports, so do a get
        num = vpc_id
        config_set('interface', 'vpc_id', name: @name, state: 'no', id: num)
      end
    end

    def default_vpc_id
      config_get_default('interface', 'vpc_id')
    end

    def vpc_peer_link
      config_get('interface', 'vpc_peer_link', name: @name)
    end

    def vpc_peer_link=(state)
      no_cmd = (state ? '' : 'no')
      config_set('interface', 'vpc_peer_link', name: @name, state: no_cmd)
    end

    def default_vpc_peer_link
      config_get_default('interface', 'vpc_peer_link')
    end

    def vrf
      config_get('interface', 'vrf', name: @name)
    end

    def vrf=(v)
      fail TypeError unless v.is_a?(String)
      return if v == vrf
      # Changing the VRF can result in loss of IP address, so cache it
      addr_1 = ipv4_address
      mask_1 = ipv4_netmask_length
      addr_2 = ipv4_address_secondary
      mask_2 = ipv4_netmask_length_secondary
      # XR actually blocks you from changing the VRF if IP addr is present
      unless platform == :nexus
        ipv4_addr_mask_set(nil, nil, false) unless addr_1.nil?
        ipv4_addr_mask_set(nil, nil, true) unless addr_2.nil?
      end
      if v.empty?
        config_set('interface', 'vrf', name: @name, state: 'no', vrf: '')
      else
        config_set('interface', 'vrf', name: @name, state: '', vrf: v)
      end
      ipv4_addr_mask_set(addr_1, mask_1, false) unless addr_1.nil?
      ipv4_addr_mask_set(addr_2, mask_2, true) unless addr_2.nil?
    end

    def default_vrf
      config_get_default('interface', 'vrf')
    end
  end  # Class
end    # Module
