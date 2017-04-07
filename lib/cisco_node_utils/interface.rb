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
require_relative 'vrf'
require_relative 'overlay_global'
require_relative 'interface_DEPRECATED'

# Cisco provider module
module Cisco
  IF_SWITCHPORT_MODE = {
    disabled:   '',
    access:     'access',
    trunk:      'trunk',
    fex_fabric: 'fex-fabric',
    tunnel:     'dot1q-tunnel',
    fabricpath: 'fabricpath',
  }

  # REMOVE THIS HASH WITH RELEASE 2.0.0
  IF_DEPRECATED = {
    host:        'host',
    promiscuous: 'promiscuous',
    secondary:   'secondary',
  }
  IF_SWITCHPORT_MODE.merge!(IF_DEPRECATED)

  # Interface - node utility class for general interface config management
  class Interface < Cisco::InterfaceDeprecated
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
      @smr = config_get('interface', 'stp_mst_range')
      @svr = config_get('interface', 'stp_vlan_range')
      @match_found = false
      create if instantiate
    end

    def to_s
      "interface #{name}"
    end

    def self.interfaces(opt=nil)
      hash = {}
      intf_list = config_get('interface', 'all_interfaces')
      return hash if intf_list.nil?

      intf_list.each do |id|
        id = id.downcase
        next if opt && filter(opt, id)
        hash[id] = Interface.new(id, false)
      end
      hash
    end

    # General-purpose filter for Interface.interfaces().
    # filter: This may be overloaded in the future to allow a hash of filters.
    #     id: The interface name
    # Return: true if the interface should be filtered out, false to keep it.
    def self.filter(filter, id)
      case filter
      when :pvlan_any
        return false if config_get('interface', 'pvlan_any', name: id)

      else
        # Just a basic pattern filter (:ethernet, :loopback, etc)
        return false if id.match(filter.to_s)
      end
      true
    end

    # 'capabilities' is a getter-only helper for minitest and beaker.
    # mode values:
    #   :hash = Transform the output into a hash
    #   :raw  = The raw output from 'show int capabilities'. Some multi-line
    #           values do not translate easily so this option allows the
    #           caller to extract the data it needs.
    #
    # Sample cli output:
    #    Model:                 N7K-M132XP-12L
    #    Type (SFP capable):    10Gbase-SR
    #    Speed:                 10,100,1000
    #
    # Sample hash output:
    # {"Model"=>"N7K-M132XP-12L", "Type"=>"10Gbase-SR", "Speed"=>"10,100,1000"}
    #
    def self.capabilities(intf, mode=:hash)
      array = config_get('interface', 'capabilities', name: intf)
      return array if mode == :raw
      hash = {}
      if array
        array.delete('')
        array.each do |line|
          k, v = line.split(':')
          next if k.nil? || v.nil?
          k.gsub!(/ \(.*\)/, '') # Remove any parenthetical text from key
          v.strip!
          v.gsub!(%r{half/full}, 'half,full') if k == 'Duplex'
          hash[k] = v
        end
      end
      hash
    end

    def create
      feature_vlan_set(true) if @name[/(vlan|bdi)/i]
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

    def pvlan_enable
      switchport_enable
      Feature.private_vlan_enable
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    # For range based attributes, a new attribute purge will
    # be added in future. When purge is set to true, all the
    # ranges which are specified in the manifest will be set
    # to the desired values and those which are not specified
    # in the manifest will be set to default. When purge is
    # false, only the ranges specified in the manifest will
    # be set to the values given in the manifest and others
    # are left untouched.

    def access_vlan
      config_get('interface', 'access_vlan', name: @name)
    end

    def access_vlan=(vlan)
      config_set('interface', 'access_vlan', name: @name, vlan: vlan)
    end

    def default_access_vlan
      config_get_default('interface', 'access_vlan')
    end

    def bfd_echo
      return nil unless Feature.bfd_enabled?
      return nil if @name[/loop/i]
      config_get('interface', 'bfd_echo', name: @name)
    end

    def bfd_echo=(val)
      fail ArgumentError, 'Interface cannot be loopback' if
        @name[/loop/i]
      return if val == bfd_echo
      state = (val ? '' : 'no')
      Feature.bfd_enable
      config_set('interface', 'bfd_echo',
                 name: @name, state: state)
    end

    def default_bfd_echo
      return nil unless Feature.bfd_enabled?
      return nil if @name[/loop/i]
      config_get_default('interface', 'bfd_echo')
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
      raise "#{e} 'fabric_forwarding_anycast_gateway' can only be " \
        'configured on a vlan interface' unless /vlan/.match(@name)
      anycast_gateway_mac = OverlayGlobal.new.anycast_gateway_mac
      if anycast_gateway_mac.nil? || anycast_gateway_mac.empty?
        raise "#{e} Anycast gateway mac must be configured " \
               'before configuring forwarding mode under interface'
      end
      raise
    end

    def default_fabric_forwarding_anycast_gateway
      config_get_default('interface', 'fabric_forwarding_anycast_gateway')
    end

    def hsrp_bfd
      config_get('interface', 'hsrp_bfd', name: @name)
    end

    def hsrp_bfd=(val)
      return if val == hsrp_bfd
      state = val ? '' : 'no'
      if val
        Feature.hsrp_enable
        Feature.bfd_enable
      end
      config_set('interface', 'hsrp_bfd', name: @name, state: state)
    end

    def default_hsrp_bfd
      config_get_default('interface', 'hsrp_bfd')
    end

    # hsrp delay minimum and reload are in the same CLI
    # hsrp delay minimum 0 reload 0
    def hsrp_delay
      match = config_get('interface', 'hsrp_delay', name: @name)
      match.nil? ? default_hsrp_delay : match.collect(&:to_i)
    end

    def default_hsrp_delay
      [default_hsrp_delay_minimum, default_hsrp_delay_reload]
    end

    def hsrp_delay_minimum
      minimum, _reload = hsrp_delay
      minimum.nil? ? default_hsrp_delay_minimum : minimum
    end

    # hsrp delay minimum and reload are in the same CLI
    # but both can be set independent of each other
    def hsrp_delay_minimum=(val)
      Feature.hsrp_enable if val
      config_set('interface', 'hsrp_delay', name: @name,
                 minimum: 'minimum', min: val, reload: '', rel: '')
    end

    def default_hsrp_delay_minimum
      config_get_default('interface', 'hsrp_delay_minimum')
    end

    def hsrp_delay_reload
      _minimum, reload = hsrp_delay
      reload.nil? ? default_hsrp_delay_reload : reload
    end

    # hsrp delay minimum and reload are in the same CLI
    # but both can be set independent of each other
    def hsrp_delay_reload=(val)
      Feature.hsrp_enable if val
      config_set('interface', 'hsrp_delay', name: @name,
                 minimum: '', min: '', reload: 'reload', rel: val)
    end

    def default_hsrp_delay_reload
      config_get_default('interface', 'hsrp_delay_reload')
    end

    def hsrp_mac_refresh
      config_get('interface', 'hsrp_mac_refresh', name: @name)
    end

    def hsrp_mac_refresh=(val)
      state = val ? '' : 'no'
      time = val ? val : ''
      Feature.hsrp_enable if val
      config_set('interface', 'hsrp_mac_refresh', name: @name,
                 state: state, timeout: time)
    end

    def default_hsrp_mac_refresh
      config_get_default('interface', 'hsrp_mac_refresh')
    end

    def hsrp_use_bia
      match = config_get('interface', 'hsrp_use_bia', name: @name)
      return default_hsrp_use_bia unless match
      match.include?('scope') ? :use_bia_intf : :use_bia
    end

    def hsrp_use_bia=(val)
      # Return early if device already set to the correct value
      return if val == hsrp_use_bia
      # need to reset before set
      if val
        Feature.hsrp_enable
        if val == :use_bia
          config_set('interface', 'hsrp_use_bia', name: name,
                     state: 'no', scope: ' scope interface')
          config_set('interface', 'hsrp_use_bia', name: name,
                     state: '', scope: '')
        else
          config_set('interface', 'hsrp_use_bia', name: name,
                     state: 'no', scope: '')
          config_set('interface', 'hsrp_use_bia', name: name,
                     state: '', scope: ' scope interface')
        end
      else
        if hsrp_use_bia == :use_bia
          config_set('interface', 'hsrp_use_bia', name: name,
                     state: 'no', scope: '')
        else
          config_set('interface', 'hsrp_use_bia', name: name,
                     state: 'no', scope: ' scope interface')
        end
      end
    end

    def default_hsrp_use_bia
      config_get_default('interface', 'hsrp_use_bia')
    end

    def hsrp_version
      config_get('interface', 'hsrp_version', name: @name)
    end

    def hsrp_version=(val)
      Feature.hsrp_enable if val
      config_set('interface', 'hsrp_version', name: name, ver: val)
    end

    def default_hsrp_version
      config_get_default('interface', 'hsrp_version')
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
      check_switchport(:disabled)
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

    def ipv4_dhcp_relay_addr
      config_get('interface', 'ipv4_dhcp_relay_addr', name: @name)
    end

    def ipv4_dhcp_relay_addr=(list)
      cur_list = ipv4_dhcp_relay_addr
      # remove the current addresses first
      unless cur_list.empty?
        cur_list.each do |addr|
          config_set('interface', 'ipv4_dhcp_relay_addr',
                     name:  @name, state: 'no', addr: addr)
        end
      end
      Feature.dhcp_enable unless list.empty?
      list.each do |addr|
        config_set('interface', 'ipv4_dhcp_relay_addr',
                   name:  @name, state: '', addr: addr)
      end
    end

    def default_ipv4_dhcp_relay_addr
      config_get_default('interface', 'ipv4_dhcp_relay_addr')
    end

    def ipv4_dhcp_relay_info_trust
      config_get('interface', 'ipv4_dhcp_relay_info_trust', name: @name)
    end

    def ipv4_dhcp_relay_info_trust=(state)
      Feature.dhcp_enable if state
      config_set('interface', 'ipv4_dhcp_relay_info_trust',
                 name:  @name, state: state ? '' : 'no')
    end

    def default_ipv4_dhcp_relay_info_trust
      config_get_default('interface', 'ipv4_dhcp_relay_info_trust')
    end

    def ipv4_dhcp_relay_src_addr_hsrp
      config_get('interface', 'ipv4_dhcp_relay_src_addr_hsrp', name: @name)
    end

    def ipv4_dhcp_relay_src_addr_hsrp=(state)
      Feature.dhcp_enable if state
      config_set('interface', 'ipv4_dhcp_relay_src_addr_hsrp',
                 name:  @name, state: state ? '' : 'no')
    end

    def default_ipv4_dhcp_relay_src_addr_hsrp
      config_get_default('interface', 'ipv4_dhcp_relay_src_addr_hsrp')
    end

    def ipv4_dhcp_relay_src_intf
      intf = config_get('interface', 'ipv4_dhcp_relay_src_intf', name: @name)
      # Normalize by downcasing and removing white space
      intf = intf.downcase.delete(' ') if intf
      intf
    end

    def ipv4_dhcp_relay_src_intf=(val)
      state = val == default_ipv4_dhcp_relay_src_intf ? 'no' : ''
      intf = val == default_ipv4_dhcp_relay_src_intf ? '' : val
      Feature.dhcp_enable if state.empty?
      config_set('interface', 'ipv4_dhcp_relay_src_intf',
                 name:  @name, state: state, intf: intf)
    end

    def default_ipv4_dhcp_relay_src_intf
      config_get_default('interface', 'ipv4_dhcp_relay_src_intf')
    end

    def ipv4_dhcp_relay_subnet_broadcast
      config_get('interface', 'ipv4_dhcp_relay_subnet_broadcast', name: @name)
    end

    def ipv4_dhcp_relay_subnet_broadcast=(state)
      Feature.dhcp_enable if state
      config_set('interface', 'ipv4_dhcp_relay_subnet_broadcast',
                 name:  @name, state: state ? '' : 'no')
    end

    def default_ipv4_dhcp_relay_subnet_broadcast
      config_get_default('interface', 'ipv4_dhcp_relay_subnet_broadcast')
    end

    def ipv4_dhcp_smart_relay
      config_get('interface', 'ipv4_dhcp_smart_relay', name: @name)
    end

    def ipv4_dhcp_smart_relay=(state)
      Feature.dhcp_enable if state
      config_set('interface', 'ipv4_dhcp_smart_relay',
                 name:  @name, state: state ? '' : 'no')
    end

    def default_ipv4_dhcp_smart_relay
      config_get_default('interface', 'ipv4_dhcp_smart_relay')
    end

    def ipv4_forwarding
      config_get('interface', 'ipv4_forwarding', name: @name)
    end

    def ipv4_forwarding=(state)
      config_set('interface', 'ipv4_forwarding',
                 name:  @name, state: state ? '' : 'no')
    end

    def default_ipv4_forwarding
      config_get_default('interface', 'ipv4_forwarding')
    end

    def ipv4_pim_sparse_mode
      config_get('interface', 'ipv4_pim_sparse_mode', name: @name)
    end

    def ipv4_pim_sparse_mode=(state)
      check_switchport(:disabled)
      Feature.pim_enable unless platform == :ios_xr
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
      check_switchport(:disabled)
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
      check_switchport(:disabled)
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

    def ipv6_dhcp_relay_addr
      config_get('interface', 'ipv6_dhcp_relay_addr', name: @name)
    end

    def ipv6_dhcp_relay_addr=(list)
      cur_list = ipv6_dhcp_relay_addr
      # remove the current addresses first
      unless cur_list.empty?
        cur_list.each do |addr|
          config_set('interface', 'ipv6_dhcp_relay_addr',
                     name:  @name, state: 'no', addr: addr)
        end
      end
      Feature.dhcp_enable unless list.empty?
      list.each do |addr|
        config_set('interface', 'ipv6_dhcp_relay_addr',
                   name:  @name, state: '', addr: addr)
      end
    end

    def default_ipv6_dhcp_relay_addr
      config_get_default('interface', 'ipv6_dhcp_relay_addr')
    end

    def ipv6_dhcp_relay_src_intf
      intf = config_get('interface', 'ipv6_dhcp_relay_src_intf', name: @name)
      # Normalize by downcasing and removing white space
      intf = intf.downcase.delete(' ') if intf
      intf
    end

    def ipv6_dhcp_relay_src_intf=(val)
      state = val == default_ipv6_dhcp_relay_src_intf ? 'no' : ''
      intf = val == default_ipv6_dhcp_relay_src_intf ? '' : val
      Feature.dhcp_enable if state.empty?
      config_set('interface', 'ipv6_dhcp_relay_src_intf',
                 name:  @name, state: state, intf: intf)
    end

    def default_ipv6_dhcp_relay_src_intf
      config_get_default('interface', 'ipv6_dhcp_relay_src_intf')
    end

    def feature_lacp?
      config_get('interface', 'feature_lacp')
    end

    def feature_lacp_set(val)
      return if feature_lacp? == val
      config_set('interface', 'feature_lacp', state: val ? '' : 'no')
    end

    def load_interval_counter_1_delay
      return nil if @name[/loop/] || @name[/ethernet.*\S+\.\d+$/]
      config_get('interface', 'load_interval_counter_1_delay', name: @name)
    end

    def load_interval_counter_1_delay=(val)
      fail ArgumentError, 'Interface cannot be sub-intf or loopback' if
        @name[/loop/] || @name[/ethernet.*\S+\.\d+$/]
      config_set('interface', 'load_interval_counter_1_delay',
                 name: @name, delay: val)
    end

    def default_load_interval_counter_1_delay
      # for vlan and bdi the default is 60
      if @name[/(vlan|bdi)/i]
        config_get_default('interface',
                           'load_interval_counter_1_delay_vlan_bdi')
      else
        config_get_default('interface', 'load_interval_counter_1_delay')
      end
    end

    def load_interval_counter_2_delay
      return nil if @name[/loop/] || @name[/ethernet.*\S+\.\d+$/]
      config_get('interface', 'load_interval_counter_2_delay', name: @name)
    end

    def load_interval_counter_2_delay=(val)
      fail ArgumentError, 'Interface cannot be sub-intf or loopback' if
        @name[/loop/] || @name[/ethernet.*\S+\.\d+$/]
      config_set('interface', 'load_interval_counter_2_delay',
                 name: @name, delay: val)
    end

    def default_load_interval_counter_2_delay
      config_get_default('interface', 'load_interval_counter_2_delay')
    end

    def load_interval_counter_3_delay
      return nil if @name[/loop/] || @name[/ethernet.*\S+\.\d+$/]
      config_get('interface', 'load_interval_counter_3_delay', name: @name)
    end

    def load_interval_counter_3_delay=(val)
      fail ArgumentError, 'Interface cannot be sub-intf or loopback' if
        @name[/loop/] || @name[/ethernet.*\S+\.\d+$/]
      state = val ? '' : 'no'
      delay = val ? val : ''
      config_set('interface', 'load_interval_counter_3_delay',
                 name: @name, state: state, delay: delay)
    end

    def default_load_interval_counter_3_delay
      config_get_default('interface', 'load_interval_counter_3_delay')
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
      check_switchport(:disabled)
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
      config_set('interface', 'speed', name: @name, speed: val)
    end

    def default_speed
      config_get_default('interface', 'speed')
    end

    def duplex
      config_get('interface', 'duplex', name: @name)
    end

    def duplex=(val)
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

    def pim_bfd
      config_get('interface', 'pim_bfd', name: @name)
    end

    def pim_bfd=(val)
      return if val == pim_bfd
      state = val ? '' : 'no'
      if val
        Feature.pim_enable
        Feature.bfd_enable
      end
      config_set('interface', 'pim_bfd', name: @name, state: state)
    end

    def default_pim_bfd
      config_get_default('interface', 'pim_bfd')
    end

    def storm_control_broadcast
      config_get('interface', 'storm_control_broadcast', name: @name)
    end

    def storm_control_broadcast=(val)
      state = val == default_storm_control_broadcast ? 'no' : ''
      level = val == default_storm_control_broadcast ? '' : val
      config_set('interface', 'storm_control_broadcast',
                 name: @name, state: state, level: level)
    end

    def default_storm_control_broadcast
      config_get_default('interface', 'storm_control_broadcast')
    end

    def storm_control_multicast
      config_get('interface', 'storm_control_multicast', name: @name)
    end

    def storm_control_multicast=(val)
      state = val == default_storm_control_multicast ? 'no' : ''
      level = val == default_storm_control_multicast ? '' : val
      config_set('interface', 'storm_control_multicast',
                 name: @name, state: state, level: level)
    end

    def default_storm_control_multicast
      config_get_default('interface', 'storm_control_multicast')
    end

    def storm_control_unicast
      config_get('interface', 'storm_control_unicast', name: @name)
    end

    def storm_control_unicast=(val)
      state = val == default_storm_control_unicast ? 'no' : ''
      level = val == default_storm_control_unicast ? '' : val
      config_set('interface', 'storm_control_unicast',
                 name: @name, state: state, level: level)
    end

    def default_storm_control_unicast
      config_get_default('interface', 'storm_control_unicast')
    end

    def stp_bpdufilter
      config_get('interface', 'stp_bpdufilter', name: @name)
    end

    def stp_bpdufilter=(val)
      check_switchport([:access, :trunk])
      if val
        state = ''
      else
        state = 'no'
        val = ''
      end
      config_set('interface',
                 'stp_bpdufilter', name: @name, state: state, filter: val)
    end

    def default_stp_bpdufilter
      config_get_default('interface', 'stp_bpdufilter')
    end

    def stp_bpduguard
      config_get('interface', 'stp_bpduguard', name: @name)
    end

    def stp_bpduguard=(val)
      if val
        state = ''
      else
        state = 'no'
        val = ''
      end
      config_set('interface',
                 'stp_bpduguard', name: @name, state: state, guard: val)
    end

    def default_stp_bpduguard
      config_get_default('interface', 'stp_bpduguard')
    end

    def stp_cost
      cost = config_get('interface', 'stp_cost', name: @name)
      cost == 'auto' ? cost : cost.to_i
    end

    def stp_cost=(val)
      check_switchport([:access, :trunk])
      config_set('interface', 'stp_cost', name: @name, cost: val)
    end

    def default_stp_cost
      config_get_default('interface', 'stp_cost')
    end

    def stp_guard
      config_get('interface', 'stp_guard', name: @name)
    end

    def stp_guard=(val)
      check_switchport([:access, :trunk])
      if val
        state = ''
      else
        state = 'no'
        val = ''
      end
      config_set('interface', 'stp_guard', name: @name, state: state,
                 guard: val)
    end

    def default_stp_guard
      config_get_default('interface', 'stp_guard')
    end

    def stp_link_type
      config_get('interface', 'stp_link_type', name: @name)
    end

    def stp_link_type=(val)
      check_switchport([:access, :trunk])
      config_set('interface', 'stp_link_type', name: @name, type: val)
    end

    def default_stp_link_type
      config_get_default('interface', 'stp_link_type')
    end

    def stp_port_priority
      config_get('interface', 'stp_port_priority', name: @name)
    end

    def stp_port_priority=(val)
      check_switchport([:access, :trunk])
      config_set('interface', 'stp_port_priority', name: @name, pp: val)
    end

    def default_stp_port_priority
      config_get_default('interface', 'stp_port_priority')
    end

    # Getter: Builds an array of mst cost commands currently
    # on the device.
    #   cli: spanning-tree mst 0,2-4,6,8-12 cost 1000
    #        spanning-tree mst 4000-4020 cost 2568
    # array: [['0,2-4,6,8-12', '1000'], ['4000-4020', '2568']]
    #
    def stp_mst_cost
      config_get('interface', 'stp_mst_cost', name: @name)
    end

    def stp_mst_cost=(list)
      check_switchport([:access, :trunk])
      config_set('interface', 'stp_mst_cost',
                 name: @name, state: 'no', range: @smr,
                 val: '') if list.empty?
      set_range_based_params(list, 'stp_mst_cost')
    end

    def default_stp_mst_cost
      config_get_default('interface', 'stp_mst_cost')
    end

    # Getter: Builds an array of mst port-priority commands
    # currently on the device.
    #   cli: spanning-tree mst 0,2-4,6,8-12 port-priority 64
    #        spanning-tree mst 4000-4020 port-priority 160
    # array: [['0,2-4,6,8-12', '64'], ['4000-4020', '160']]
    #
    def stp_mst_port_priority
      config_get('interface', 'stp_mst_port_priority', name: @name)
    end

    def stp_mst_port_priority=(list)
      check_switchport([:access, :trunk])
      config_set('interface', 'stp_mst_port_priority',
                 name: @name, state: 'no', range: @smr,
                 val: '') if list.empty?
      set_range_based_params(list, 'stp_mst_port_priority')
    end

    def default_stp_mst_port_priority
      config_get_default('interface', 'stp_mst_port_priority')
    end

    def stp_port_type
      config_get('interface', 'stp_port_type', name: @name)
    end

    def stp_port_type=(val)
      if val
        state = ''
      else
        state = 'no'
        val = ''
      end
      config_set('interface', 'stp_port_type', name: @name,
                 state: state, type: val)
    end

    def default_stp_port_type
      config_get_default('interface', 'stp_port_type')
    end

    # Getter: Builds an array of vlan cost commands currently
    # on the device.
    #   cli: spanning-tree vlan 1-4,6,8-12 cost 1000
    #        spanning-tree vlan 3000-3960 cost 2568
    # array: [['1-4,6,8-12', '1000'], ['3000-3960', '2568']]
    #
    def stp_vlan_cost
      config_get('interface', 'stp_vlan_cost', name: @name)
    end

    def stp_vlan_cost=(list)
      check_switchport([:access, :trunk])
      config_set('interface', 'stp_vlan_cost',
                 name: @name, state: 'no',
                 range: @svr, val: '') if list.empty?
      set_range_based_params(list, 'stp_vlan_cost')
    end

    def default_stp_vlan_cost
      config_get_default('interface', 'stp_vlan_cost')
    end

    # Getter: Builds an array of vlan port-priority commands
    # currently on the device.
    #   cli: spanning-tree vlan 1-4,6,8-12 port-priority 64
    #        spanning-tree vlan 3000-3960 port-priority 160
    # array: [['1-4,6,8-12', '64'], ['3000-3960', '160']]
    #
    def stp_vlan_port_priority
      config_get('interface', 'stp_vlan_port_priority', name: @name)
    end

    def stp_vlan_port_priority=(list)
      check_switchport([:access, :trunk])
      config_set('interface', 'stp_vlan_port_priority',
                 name: @name, state: 'no',
                 range: @svr, val: '') if list.empty?
      set_range_based_params(list, 'stp_vlan_port_priority')
    end

    def default_stp_vlan_port_priority
      config_get_default('interface', 'stp_vlan_port_priority')
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
      switchport_enable

      if :fabricpath == mode_set
        fabricpath_feature_set(:enabled) unless :enabled == fabricpath_feature
      elsif :fex_fabric == mode_set
        Feature.fex_enable
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
      vlans = config_get('interface', 'switchport_trunk_allowed_vlan',
                         name: @name)
      vlans = vlans.join(',') if vlans.is_a?(Array)
      vlans = Utils.normalize_range_array(vlans, :string) unless vlans == 'none'
      vlans
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

    # --------------------------
    def cli_error_check(result)
      # Check for messages that can be safely ignored.
      # The NXOS interface private-vlan cli does not raise an exception
      # in some conditions and instead just displays a STDOUT error message
      # thus NXAPI does not detect the failure.
      # We must catch it by inspecting the "body" hash entry returned by NXAPI.
      # This vlan cli behavior is unlikely to change.

      errors = /(ERROR:|VLAN:|Eth)/
      return unless
        result[1].is_a?(Hash) && errors.match(result[1]['body'].to_s)
      # Split errors into a list, but keep the delimiter as part of the message.
      error_list =
        (result[1]['body'].split(errors) - ['']).each_slice(2).map(&:join)
      error_list.each do |_msg|
        fail result[1]['body']
      end
    end

    # --------------------------
    # <state> switchport mode private-vlan host
    def switchport_pvlan_host
      config_get('interface', 'switchport_pvlan_host', name: @name)
    end

    def switchport_pvlan_host=(state)
      pvlan_enable
      config_set('interface', 'switchport_pvlan_host',
                 name: @name, state: state ? '' : 'no')
    end

    def default_switchport_pvlan_host
      config_get_default('interface', 'switchport_pvlan_host')
    end

    # --------------------------
    # <state> switchport mode private-vlan promiscuous
    def switchport_pvlan_promiscuous
      config_get('interface', 'switchport_pvlan_promiscuous', name: @name)
    end

    def switchport_pvlan_promiscuous=(state)
      pvlan_enable
      config_set('interface', 'switchport_pvlan_promiscuous',
                 name: @name, state: state ? '' : 'no')
    end

    def default_switchport_pvlan_promiscuous
      config_get_default('interface', 'switchport_pvlan_promiscuous')
    end

    # --------------------------
    # <state> switchport private-vlan host-association <pri> <sec>
    # Note this is NOT a multiple, unlike trunk association.
    def switchport_pvlan_host_association
      config_get('interface', 'switchport_pvlan_host_association', name: @name)
    end

    # Input: An array of primary and secondary vlans: ['44', '244']
    def switchport_pvlan_host_association=(pri_and_sec)
      pvlan_enable

      state = pri_and_sec.empty? ? 'no' : ''
      pri, sec = pri_and_sec
      cli_error_check(
        config_set('interface', 'switchport_pvlan_host_association',
                   name: @name, state: state, pri: pri, sec: sec))
    end

    def default_switchport_pvlan_host_association
      config_get_default('interface', 'switchport_pvlan_host_association')
    end

    # --------------------------
    # <state> switchport private-vlan mapping <primary> <vlan>
    def switchport_pvlan_mapping
      config_get('interface', 'switchport_pvlan_mapping', name: @name)
    end

    # Input: An array of primary vlan and range of vlans: ['44', '3-4,6']
    def switchport_pvlan_mapping=(primary_and_range)
      switchport_pvlan_mapping_delta(primary_and_range)
    end

    def default_switchport_pvlan_mapping
      config_get_default('interface', 'switchport_pvlan_mapping')
    end

    # --------------------------
    # Find the is/should delta and add/remove commands as needed.
    #
    # Inputs:
    # primary_and_range: An array of primary vlan and range of vlans
    def switchport_pvlan_mapping_delta(primary_and_range)
      # Enable switchport mode and feature private-vlan
      pvlan_enable
      primary, should_range = primary_and_range

      # primary changes require removing the entire command first
      is_range = switchport_pvlan_mapping_remove?(primary)

      # convert ranges to individual elements
      is = Utils.dash_range_to_elements(is_range)
      should = Utils.dash_range_to_elements(should_range)

      # create the delta hash and apply the changes
      delta_hash = Utils.delta_add_remove(should, is)
      Cisco::Logger.debug('switchport_pvlan_mapping_delta: '\
                          "#{primary}: #{delta_hash}")
      [:add, :remove].each do |action|
        delta_hash[action].each do |vlan|
          state = (action == :add) ? '' : 'no'
          cli_error_check(
            config_set('interface', 'switchport_pvlan_mapping',
                       name: @name, state: state, primary: primary, vlan: vlan))
        end
      end
    end

    # --------------------------
    # switchport_pvlan_mapping_remove?
    # This is a helper to check if command needs to be removed entirely.
    #
    # should_primary: the new primary vlan value
    #        Returns: the current vlan range
    def switchport_pvlan_mapping_remove?(should_primary)
      is_primary, is_range = switchport_pvlan_mapping

      if (is_primary != should_primary) && !is_primary.nil?
        cli_error_check(
          config_set('interface', 'switchport_pvlan_mapping',
                     name: @name, state: 'no', primary: '', vlan: ''))
        is_range = []
      end
      is_range
    end

    # --------------------------
    # <state> switchport private-vlan mapping trunk <primary> <vlan>
    def switchport_pvlan_mapping_trunk
      config_get('interface', 'switchport_pvlan_mapping_trunk', name: @name)
    end

    # Input: A nested array of primary vlan and range of vlans:
    # [['44', '3-4,6'], ['99', '199']]
    def switchport_pvlan_mapping_trunk=(should)
      switchport_pvlan_mapping_trunk_delta(should)
    end

    def default_switchport_pvlan_mapping_trunk
      config_get_default('interface', 'switchport_pvlan_mapping_trunk')
    end

    # --------------------------
    # switchport_pvlan_mapping_trunk_delta(should)
    #
    # Find the is/should delta and add/remove commands as needed.
    # The 'should' value is a nested array of primary vlan and secondary
    # ranges; e.g.:
    #   [['44', '144-145'], ['99', '199-201']
    #
    def switchport_pvlan_mapping_trunk_delta(should)
      # Enable switchport mode and feature private-vlan
      pvlan_enable

      # Handle single-level arrays if found: [pri, range] -> [[pri,range]]
      should = [should] if !should.empty? && (Utils.depth(should) == 1)

      is = switchport_pvlan_mapping_trunk
      delta_hash = Utils.delta_add_remove(should, is, :updates_not_allowed)
      Cisco::Logger.debug("switchport_pvlan_mapping_trunk_delta: #{delta_hash}")
      [:remove, :add].each do |action|
        delta_hash[action].each do |pri_and_range|
          pri, range = pri_and_range
          if action == :add
            state = ''
          else
            state = 'no'
            range = ''
          end
          cli_error_check(
            config_set('interface', 'switchport_pvlan_mapping_trunk',
                       name: @name, state: state, primary: pri, range: range))
        end
      end
    end

    # --------------------------
    # <state> switchport private-vlan association trunk <pri> <sec>
    # Supports multiple.
    def switchport_pvlan_trunk_association
      config_get('interface', 'switchport_pvlan_trunk_association', name: @name)
    end

    # Input: A nested array of primary and secondary vlans:
    # [['44', '244'], ['99', '299']]
    def switchport_pvlan_trunk_association=(should)
      pvlan_enable

      # Handle single-level arrays if found: [pri, sec] -> [[pri,sec]]
      should = [should] if !should.empty? && (Utils.depth(should) == 1)

      is = switchport_pvlan_trunk_association
      pvlan_trunk_association_delta(is, should)
    end

    def pvlan_trunk_association_delta(is, should)
      delta_hash = Utils.delta_add_remove(should, is)
      Cisco::Logger.debug("pvlan_trunk_association_delta: #{delta_hash}")
      [:remove, :add].each do |action|
        delta_hash[action].each do |pri_and_sec|
          state = (action == :add) ? '' : 'no'
          pri, sec = pri_and_sec

          # Cli does not like removals that specify the secondary
          sec = '' if action[/remove/]
          cli_error_check(
            config_set('interface', 'switchport_pvlan_trunk_association',
                       name: @name, state: state, pri: pri, sec: sec))
        end
      end
    end

    def default_switchport_pvlan_trunk_association
      config_get_default('interface', 'switchport_pvlan_trunk_association')
    end

    # --------------------------
    # <state> switchport mode private-vlan trunk promiscuous
    def switchport_pvlan_trunk_promiscuous
      config_get('interface', 'switchport_pvlan_trunk_promiscuous', name: @name)
    end

    def switchport_pvlan_trunk_promiscuous=(state)
      pvlan_enable
      config_set('interface', 'switchport_pvlan_trunk_promiscuous',
                 name: @name, state: state ? '' : 'no')
    end

    def default_switchport_pvlan_trunk_promiscuous
      config_get_default('interface', 'switchport_pvlan_trunk_promiscuous')
    end

    # --------------------------
    # <state> switchport mode private-vlan trunk secondary
    def switchport_pvlan_trunk_secondary
      config_get('interface', 'switchport_pvlan_trunk_secondary', name: @name)
    end

    def switchport_pvlan_trunk_secondary=(state)
      pvlan_enable
      config_set('interface', 'switchport_pvlan_trunk_secondary',
                 name: @name, state: state ? '' : 'no')
    end

    def default_switchport_pvlan_trunk_secondary
      config_get_default('interface', 'switchport_pvlan_trunk_secondary')
    end

    # --------------------------
    # <state> switchport private-vlan trunk allowed vlan <range>
    # Note that range is handled as a string because the entire range is
    # replaced instead of individually adding or removing vlans from the range.
    def switchport_pvlan_trunk_allowed_vlan
      vlans = config_get('interface', 'switchport_pvlan_trunk_allowed_vlan',
                         name: @name)
      vlans = vlans.join(',') if vlans.is_a?(Array)
      vlans = Utils.normalize_range_array(vlans, :string) unless vlans == 'none'
      vlans
    end

    def switchport_pvlan_trunk_allowed_vlan=(range)
      pvlan_enable

      range = Utils.normalize_range_array(range, :string) unless
        range == default_switchport_pvlan_trunk_allowed_vlan

      config_set('interface', 'switchport_pvlan_trunk_allowed_vlan',
                 name: @name, range: range)
    end

    def default_switchport_pvlan_trunk_allowed_vlan
      config_get_default('interface', 'switchport_pvlan_trunk_allowed_vlan')
    end

    # --------------------------
    # <state> switchport trunk native vlan <vlan>
    def switchport_pvlan_trunk_native_vlan
      config_get('interface', 'switchport_pvlan_trunk_native_vlan', name: @name)
    end

    def switchport_pvlan_trunk_native_vlan=(vlan)
      pvlan_enable
      config_set('interface', 'switchport_pvlan_trunk_native_vlan',
                 name: @name, vlan: vlan)
    end

    def default_switchport_pvlan_trunk_native_vlan
      config_get_default('interface', 'switchport_pvlan_trunk_native_vlan')
    end

    # --------------------------
    # This is an SVI property.
    # <state> private-vlan mapping <range>  # ex. range = ['2-4,9']
    # Always returns an array.
    def pvlan_mapping
      range = config_get('interface', 'pvlan_mapping', name: @name)
      return default_pvlan_mapping if range.nil?
      range.empty? ? range : [range.delete(' ')]
    end

    def pvlan_mapping=(range)
      feature_vlan_set
      Feature.private_vlan_enable

      is = Utils.dash_range_to_elements(pvlan_mapping)
      should = Utils.dash_range_to_elements(range)

      pvlan_mapping_delta(is, should)
    end

    def pvlan_mapping_delta(is, should)
      delta_hash = Utils.delta_add_remove(should, is)
      Cisco::Logger.debug("pvlan_mapping_delta: #{delta_hash}")
      [:remove, :add].each do |action|
        delta_hash[action].each do |vlan|
          state = (action == :add) ? '' : 'no'
          cli_error_check(
            config_set('interface', 'pvlan_mapping',
                       name: @name, state: state, vlan: vlan))
        end
      end
    end

    def default_pvlan_mapping
      config_get_default('interface', 'pvlan_mapping')
    end

    # --------------------------
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
      # TODO: throw UnsupportedError instead of returning false?
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
      check_switchport(:disabled)
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

    def feature_vlan_set(val=true)
      # 'feature interface-vlan'
      # TBD: Replace this with Feature.interface_vlan_enable
      return if feature_vlan? == val
      config_set('interface', 'feature_vlan', state: val ? '' : 'no')
    end

    # svi_management is exclusive to svi interfaces
    def svi_management
      return nil unless @name[/^vlan/i]
      config_get('interface', 'svi_management', name: @name)
    end

    def svi_management=(val)
      check_switchport(:disabled)
      svi_cmd_allowed?('management')
      config_set('interface', 'svi_management',
                 name: @name, state: val ? '' : 'no')
    end

    def default_svi_management
      config_get_default('interface', 'svi_management')
    end

    def default_switchport_vtp
      return nil unless switchport_vtp_mode_capable?
      config_get_default('interface', 'vtp')
    end

    def switchport_vtp_feature?
      config_get('vtp', 'feature')
    end

    def switchport_status?(status)
      case status
      when :disabled
        return true if switchport_mode == status || switchport_mode.nil?
      when :access, :trunk
        return switchport_mode == status
      when Array
        return status.include?(switchport_mode)
      else
        return false
      end
    end

    def check_switchport(status)
      return if switchport_status?(status)
      fail("#{caller[0][/`.*'/][1..-2]} cannot be set unless " \
           "switchport mode is #{status}")
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

    def set_range_based_params(list, param_name)
      list.each do |range, property_value|
        # if a particular range is set to default, use 'no' cmd
        if property_value == 'default'
          config_set('interface', param_name,
                     name: @name, state: 'no',
                     range: range, val: '')
        else
          config_set('interface', param_name,
                     name: @name, state: '',
                     range: range, val: property_value)
        end
      end
    end

    def purge_config=(val)
      return unless val
      fail ArgumentError,
           'purge_config is only supported on Ethernet interfaces' unless
        @name[/ethernet/]
      config_set('interface', 'purge_config', name: @name) if val
    end

    def purge_config
      state = config_get('interface', 'purge_config', name: @name)
      state.nil? ? true : false
    end
  end  # Class
end    # Module
