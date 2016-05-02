# VRF provider class
#
# Jie Yang, July 2015
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
require_relative 'feature'

module Cisco
  # Vrf - node utility class for VRF configuration management
  class Vrf < NodeUtil
    attr_reader :name

    def initialize(name, instantiate=true)
      fail TypeError unless name.is_a?(String)
      @name = name.downcase.strip
      create if instantiate
    end

    def to_s
      "VRF #{@name}"
    end

    def self.vrfs
      hash = {}
      vrf_list = config_get('vrf', 'all_vrfs')
      return hash if vrf_list.nil?

      vrf_list.each do |id|
        id = id.downcase.strip
        hash[id] = Vrf.new(id, false)
      end
      hash
    end

    def create
      config_set('vrf', 'create', vrf: @name)
    end

    def destroy
      config_set('vrf', 'destroy', vrf: @name)
    end

    ########################################################
    #                      PROPERTIES                      #
    ########################################################

    def description
      config_get('vrf', 'description', vrf: @name)
    end

    def description=(desc)
      fail TypeError unless desc.is_a?(String)
      desc.strip!
      no_cmd = desc.empty? ? 'no' : ''
      config_set('vrf', 'description', vrf: @name, state: no_cmd, desc: desc)
    end

    def default_description
      config_get_default('vrf', 'description')
    end

    def mhost_ipv4_default_interface
      config_get('vrf', 'mhost_default_interface', vrf: @name, afi: 'ipv4')
    end

    def mhost_ipv4_default_interface=(val)
      mhost_default_interface_setter_helper('ipv4', val)
    end

    def default_mhost_ipv4_default_interface
      config_get_default('vrf', 'mhost_default_interface')
    end

    def mhost_ipv6_default_interface
      config_get('vrf', 'mhost_default_interface', vrf: @name, afi: 'ipv6')
    end

    def mhost_ipv6_default_interface=(val)
      mhost_default_interface_setter_helper('ipv6', val)
    end

    def default_mhost_ipv6_default_interface
      config_get_default('vrf', 'mhost_default_interface')
    end

    def mhost_default_interface_setter_helper(afi, val)
      val.strip!
      no_cmd = val.empty? ? 'no' : ''
      config_set('vrf', 'mhost_default_interface', vrf: @name,
                 state: no_cmd, afi: afi, intf: val)
    end

    def remote_route_filtering
      config_get('vrf', 'remote_route_filtering', vrf: @name)
    end

    def remote_route_filtering=(val)
      no_cmd = val ? 'no' : ''
      config_set('vrf', 'remote_route_filtering', vrf: @name,
                 state: no_cmd, remote_route_filtering: val)
    end

    def default_remote_route_filtering
      config_get_default('vrf', 'remote_route_filtering')
    end

    def shutdown
      config_get('vrf', 'shutdown', vrf: @name)
    end

    def shutdown=(val)
      no_cmd = (val) ? '' : 'no'
      config_set('vrf', 'shutdown', vrf: @name, state: no_cmd)
    end

    def default_shutdown
      config_get_default('vrf', 'shutdown')
    end

    # route_distinguisher
    # Note that this property is supported by both bgp and vrf providers.
    def route_distinguisher
      config_get('vrf', 'route_distinguisher', vrf: @name)
    end

    def route_distinguisher=(rd)
      # feature bgp and nv overlay required for rd cli in NXOS
      if platform == :nexus
        Feature.bgp_enable
        Feature.nv_overlay_enable if Feature.nv_overlay_supported?
        Feature.nv_overlay_evpn_enable if Feature.nv_overlay_evpn_supported?
      end
      if rd == default_route_distinguisher
        state = 'no'
        # I2 images require an rd for removal
        rd = route_distinguisher
        return if rd.to_s.empty?
      else
        state = ''
      end
      config_set('vrf', 'route_distinguisher', state: state, vrf: @name, rd: rd)
    end

    def default_route_distinguisher
      config_get_default('vrf', 'route_distinguisher')
    end

    # Vni (Getter/Setter/Default)
    def vni
      config_get('vrf', 'vni', vrf: @name)
    end

    def vni=(id)
      Feature.vn_segment_vlan_based_enable if platform == :nexus
      no_cmd = (id) ? '' : 'no'
      id = (id) ? id : vni
      config_set('vrf', 'vni', vrf: @name, state: no_cmd, id: id)
    end

    def default_vni
      config_get_default('vrf', 'vni')
    end

    def vpn_id
      config_get('vrf', 'vpn_id', vrf: @name)
    end

    def vpn_id=(val)
      val.strip!
      no_cmd = val.empty? ? 'no' : ''
      config_set('vrf', 'vpn_id', vrf: @name, state: no_cmd, vpnid: val)
    end

    def default_vpn_id
      config_get_default('vrf', 'vpn_id')
    end
  end # class
end # module
